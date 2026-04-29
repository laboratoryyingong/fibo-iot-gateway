const { requireHomeContext } = require('../lib/auth');
const { getCloudConfig } = require('../lib/cloud_config');
const { invalidArgument, notFound, unauthenticated } = require('../lib/errors');

async function getAwsIotSession(request) {
  if (!request.user) {
    throw unauthenticated();
  }

  const gateway = await resolveGatewayForUser(request);
  const home = gateway.get('home');
  if (!home) {
    throw notFound('Gateway is not linked to a home.', {
      gatewayId: gateway.get('gatewayId'),
    });
  }

  const { membership, role } = await requireHomeContext({
    user: request.user,
    homeId: home.get('homeId'),
  });

  const config = getCloudConfig();
  const gatewayId = gateway.get('gatewayId');

  return {
    homeId: home.get('homeId'),
    gatewayId,
    thingName: gateway.get('thingName'),
    role,
    awsIdentity: {
      region: config.awsRegion,
      identityPoolId: config.awsIdentityPoolId,
      identityProvider: config.awsIdentityProvider,
      developerTokenMode: config.developerTokenMode,
      developerToken: null,
      credentials: null,
    },
    iotScope: {
      allowedShadowPrefixes: resolveAllowedShadowPrefixes(role),
      allowedTopicPrefix: `${config.iotTopicPrefixBase}/${home.get('homeId')}/${gatewayId}/`,
    },
    membership: {
      status: membership.get('status'),
    },
    // TODO: replace placeholder identity fields with real Cognito developer-auth flow.
  };
}

async function resolveGatewayForUser(request) {
  const gatewayId = request.params.gatewayId;
  if (gatewayId != null && (typeof gatewayId !== 'string' || gatewayId.trim() === '')) {
    throw invalidArgument('`gatewayId` must be a non-empty string when provided.');
  }

  const memberQuery = new Parse.Query('HomeMember');
  memberQuery.equalTo('user', request.user);
  memberQuery.equalTo('status', 'active');
  memberQuery.include('home');
  const memberships = await memberQuery.find({ useMasterKey: true });
  if (memberships.length === 0) {
    throw notFound('User does not belong to any active home.');
  }

  const homes = memberships.map((membership) => membership.get('home')).filter(Boolean);
  const gatewayQuery = new Parse.Query('Gateway');
  gatewayQuery.containedIn('home', homes);
  gatewayQuery.include('home');
  if (gatewayId) {
    gatewayQuery.equalTo('gatewayId', gatewayId.trim());
  }
  const gateways = await gatewayQuery.find({ useMasterKey: true });

  if (gatewayId) {
    if (gateways.length === 0) {
      throw notFound('Gateway was not found for this user.', { gatewayId });
    }
    return gateways[0];
  }

  if (gateways.length !== 1) {
    throw invalidArgument(
      '`gatewayId` is required when the user can access more than one gateway.',
      { gatewayCount: gateways.length },
    );
  }

  return gateways[0];
}

function resolveAllowedShadowPrefixes(role) {
  if (role === 'installer' || role === 'admin') {
    return ['dev_', 'admin', 'hub'];
  }
  if (role === 'member') {
    return ['dev_', 'hub'];
  }
  return ['hub'];
}

module.exports = { getAwsIotSession };
