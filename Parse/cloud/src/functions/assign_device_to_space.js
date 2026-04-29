const { requireHomeContext } = require('../lib/auth');
const { invalidArgument, notFound } = require('../lib/errors');
const { serializeDevice } = require('../lib/serialize');

async function assignDeviceToSpace(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['installer', 'admin'],
  });

  const endpointKey = normalizeNonEmptyString(
    request.params.endpointKey,
    '`endpointKey` must be a non-empty string.',
  );

  const deviceQuery = new Parse.Query('DeviceEndpoint');
  deviceQuery.equalTo('home', home);
  deviceQuery.equalTo('endpointKey', endpointKey);
  deviceQuery.include(['gateway', 'space']);
  const device = await deviceQuery.first({ useMasterKey: true });
  if (!device) {
    throw notFound('DeviceEndpoint was not found in this home.', { endpointKey });
  }

  const spaceId = request.params.spaceId;
  let space = null;
  if (spaceId !== null && spaceId !== undefined) {
    const normalizedSpaceId = normalizeNonEmptyString(
      spaceId,
      '`spaceId` must be a non-empty string when provided.',
    );
    const spaceQuery = new Parse.Query('Space');
    spaceQuery.equalTo('home', home);
    spaceQuery.equalTo('spaceId', normalizedSpaceId);
    space = await spaceQuery.first({ useMasterKey: true });
    if (!space) {
      throw notFound('Space was not found in this home.', { spaceId: normalizedSpaceId });
    }
  }

  device.set('space', space);
  if (request.params.sortOrder !== undefined) {
    if (!Number.isFinite(request.params.sortOrder)) {
      throw invalidArgument('`sortOrder` must be a finite number when provided.');
    }
    device.set('sortOrder', Number(request.params.sortOrder));
  }

  await device.save(null, { useMasterKey: true });
  await device.fetchWithInclude(['gateway', 'space'], { useMasterKey: true });

  return {
    device: {
      ...serializeDevice(device),
      updatedAt: device.updatedAt ? device.updatedAt.toISOString() : null,
    },
  };
}

function normalizeNonEmptyString(value, message) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw invalidArgument(message);
  }
  return value.trim();
}

module.exports = { assignDeviceToSpace };
