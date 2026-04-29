const {
  forbidden,
  invalidArgument,
  notFound,
  unauthenticated,
} = require('./errors');

async function requireHomeContext({ user, homeId, allowedRoles = null }) {
  if (!user) {
    throw unauthenticated();
  }

  if (typeof homeId !== 'string' || homeId.trim() === '') {
    throw invalidArgument('`homeId` must be a non-empty string.');
  }

  const homeQuery = new Parse.Query('Home');
  homeQuery.equalTo('homeId', homeId.trim());
  const home = await homeQuery.first({ useMasterKey: true });
  if (!home) {
    throw notFound('Home was not found.', { homeId });
  }

  const membershipQuery = new Parse.Query('HomeMember');
  membershipQuery.equalTo('home', home);
  membershipQuery.equalTo('user', user);
  membershipQuery.equalTo('status', 'active');
  const membership = await membershipQuery.first({ useMasterKey: true });
  if (!membership) {
    throw forbidden('User does not have active membership in this home.');
  }

  const role = membership.get('role');
  if (Array.isArray(allowedRoles) && allowedRoles.length > 0) {
    if (!allowedRoles.includes(role)) {
      throw forbidden('User does not have permission for this operation.');
    }
  }

  return { home, membership, role };
}

module.exports = { requireHomeContext };
