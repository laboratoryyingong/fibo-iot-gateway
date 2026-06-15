const { requireHomeContext } = require('../lib/auth');
const { conflict, invalidArgument, notFound } = require('../lib/errors');

// Removes a member from the home (soft: status -> suspended, so listHomeGraph
// stops returning them). Admin-only. Refuses to remove the last active admin.
async function removeHomeMember(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['admin'],
  });

  const userId =
    typeof request.params.userId === 'string'
      ? request.params.userId.trim()
      : '';
  if (userId === '') {
    throw invalidArgument('`userId` is required.');
  }

  const target = new Parse.User();
  target.id = userId;

  const memberQuery = new Parse.Query('HomeMember');
  memberQuery.equalTo('home', home);
  memberQuery.equalTo('user', target);
  const membership = await memberQuery.first({ useMasterKey: true });
  if (!membership || membership.get('status') !== 'active') {
    throw notFound('That member was not found in this home.', { userId });
  }

  if (membership.get('role') === 'admin') {
    const adminQuery = new Parse.Query('HomeMember');
    adminQuery.equalTo('home', home);
    adminQuery.equalTo('role', 'admin');
    adminQuery.equalTo('status', 'active');
    const adminCount = await adminQuery.count({ useMasterKey: true });
    if (adminCount <= 1) {
      throw conflict('You cannot remove the last admin of the home.');
    }
  }

  membership.set('status', 'suspended');
  await membership.save(null, { useMasterKey: true });
  return { removedUserId: userId };
}

module.exports = { removeHomeMember };
