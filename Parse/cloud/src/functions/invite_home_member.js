const { requireHomeContext } = require('../lib/auth');
const { conflict, invalidArgument, notFound } = require('../lib/errors');
const { createBusinessId } = require('../lib/ids');
const { serializeMember } = require('../lib/serialize');

const ALLOWED_ROLES = ['admin', 'member', 'guest'];

// Adds an existing account to the home as a member. Admin-only. The invitee must
// already have a Fibo account (looked up by email/username); a suspended prior
// membership is re-activated rather than duplicated.
async function inviteHomeMember(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['admin'],
  });

  const email =
    typeof request.params.email === 'string'
      ? request.params.email.trim().toLowerCase()
      : '';
  if (email === '') {
    throw invalidArgument('`email` is required.');
  }
  const role = ALLOWED_ROLES.includes(request.params.role)
    ? request.params.role
    : 'member';

  const byEmail = new Parse.Query(Parse.User);
  byEmail.equalTo('email', email);
  const byUsername = new Parse.Query(Parse.User);
  byUsername.equalTo('username', email);
  const user = await Parse.Query.or(byEmail, byUsername).first({
    useMasterKey: true,
  });
  if (!user) {
    throw notFound('No account found with that email. Ask them to sign up first.', {
      email,
    });
  }

  const existingQuery = new Parse.Query('HomeMember');
  existingQuery.equalTo('home', home);
  existingQuery.equalTo('user', user);
  let membership = await existingQuery.first({ useMasterKey: true });
  if (membership && membership.get('status') === 'active') {
    throw conflict('That person is already a member of this home.', { email });
  }
  if (!membership) {
    membership = new Parse.Object('HomeMember');
    membership.set('memberId', createBusinessId('member'));
    membership.set('home', home);
    membership.set('user', user);
    membership.set('invitedBy', request.user);
  }
  membership.set('role', role);
  membership.set('status', 'active');
  await membership.save(null, { useMasterKey: true });

  // `user` is already the full object, so serialization can read its fields.
  membership.set('user', user);
  return { member: serializeMember(membership) };
}

module.exports = { inviteHomeMember };
