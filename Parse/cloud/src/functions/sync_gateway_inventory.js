const {
  IoTDataPlaneClient,
  GetThingShadowCommand,
} = require('@aws-sdk/client-iot-data-plane');
const { requireHomeContext } = require('../lib/auth');
const { getCloudConfig } = require('../lib/cloud_config');
const { invalidArgument, notFound } = require('../lib/errors');

/// Reconciles Parse `Space` + `DeviceEndpoint` rows from the gateway's live
/// `admin` shadow (its device registry + room list). Run once after binding a
/// gateway, and again whenever devices/rooms change.
///
/// Source of truth for *structure* = the admin shadow:
///   reported.rooms          -> Space
///   reported.devices        -> DeviceEndpoint (ieee/ep/profile/type/online)
///   desired.device_tags     -> name / room / alias / dangerous
async function syncGatewayInventory(request) {
  const { home, role } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['installer', 'admin'],
  });

  const gateway = await resolveGateway(home, request.params.gatewayId);
  const gatewayId = gateway.get('gatewayId');
  const thingName = gateway.get('thingName');

  const admin = await readAdminShadow(thingName);
  const reported = admin.state?.reported || {};
  const desired = admin.state?.desired || {};
  const rooms = Array.isArray(reported.rooms) ? reported.rooms : [];
  const devices = reported.devices || {};
  const tags = desired.device_tags || {};

  const summary = { spacesUpserted: 0, created: 0, updated: 0, unchanged: 0 };

  // 1. Spaces from rooms.
  const spaceByRoomId = {};
  let sortOrder = 100;
  for (const room of rooms) {
    if (!room || !room.id) continue;
    const space = await upsertSpace(home, room, sortOrder);
    spaceByRoomId[room.id] = space;
    sortOrder += 10;
    summary.spacesUpserted += 1;
  }

  // 2. DeviceEndpoints from devices + device_tags.
  let devSort = 100;
  for (const key of Object.keys(devices)) {
    const dev = devices[key];
    if (!dev || dev.ieee == null || dev.ep == null) continue;
    const tag = tags[key] || {};
    const shadowName = `dev_${dev.ieee}_ep${dev.ep}`;
    const endpointKey = `${gatewayId}:${dev.ieee}:ep${dev.ep}`;
    const space = tag.room ? spaceByRoomId[tag.room] || null : null;

    const result = await upsertDeviceEndpoint({
      home,
      gateway,
      thingName,
      endpointKey,
      shadowName,
      ieee: String(dev.ieee),
      ep: Number(dev.ep),
      profile: dev.profile || 'unknown',
      displayName: tag.name || tag.alias || shadowName,
      iconKey: iconKeyForProfile(dev.profile),
      space,
      sortOrder: devSort,
      online: dev.online === true,
    });
    devSort += 10;
    summary[result] += 1;
  }

  return { gatewayId, role, summary };
}

async function resolveGateway(home, gatewayId) {
  const q = new Parse.Query('Gateway');
  q.equalTo('home', home);
  if (typeof gatewayId === 'string' && gatewayId.trim() !== '') {
    q.equalTo('gatewayId', gatewayId.trim());
  }
  const gateway = await q.first({ useMasterKey: true });
  if (!gateway) {
    throw notFound('No gateway found for this home.', { gatewayId });
  }
  return gateway;
}

async function readAdminShadow(thingName) {
  const config = getCloudConfig();
  if (!config.iotDataEndpoint) {
    throw invalidArgument('FIBO_IOT_DATA_ENDPOINT is not configured.');
  }
  const client = new IoTDataPlaneClient({
    region: config.awsRegion,
    endpoint: `https://${config.iotDataEndpoint}`,
  });
  const out = await client.send(
    new GetThingShadowCommand({ thingName, shadowName: 'admin' })
  );
  const text = Buffer.from(out.payload).toString('utf8');
  return JSON.parse(text);
}

async function upsertSpace(home, room, sortOrder) {
  const q = new Parse.Query('Space');
  q.equalTo('home', home);
  q.equalTo('spaceId', room.id);
  let space = await q.first({ useMasterKey: true });
  if (!space) {
    space = new Parse.Object('Space');
    space.set('spaceId', room.id);
    space.set('home', home);
  }
  space.set('name', room.name || room.id);
  space.set('status', 'active');
  if (space.get('sortOrder') == null) space.set('sortOrder', sortOrder);
  await space.save(null, { useMasterKey: true });
  return space;
}

async function upsertDeviceEndpoint(p) {
  const q = new Parse.Query('DeviceEndpoint');
  q.equalTo('endpointKey', p.endpointKey);
  let device = await q.first({ useMasterKey: true });
  const isNew = !device;
  if (isNew) {
    device = new Parse.Object('DeviceEndpoint');
    device.set('endpointKey', p.endpointKey);
    // displayName / space are user-editable: only set on create so a later
    // sync never clobbers a name/room the user customised in the app.
    device.set('displayName', p.displayName);
    if (p.space) device.set('space', p.space);
    device.set('sortOrder', p.sortOrder);
  }
  device.set('home', p.home);
  device.set('gateway', p.gateway);
  device.set('thingName', p.thingName);
  device.set('shadowName', p.shadowName);
  device.set('ieee', p.ieee);
  device.set('ep', p.ep);
  device.set('profile', p.profile);
  device.set('iconKey', p.iconKey);
  device.set('lastKnownOnline', p.online);
  device.set('status', 'active');
  await device.save(null, { useMasterKey: true });
  return isNew ? 'created' : 'updated';
}

function iconKeyForProfile(profile) {
  switch (profile) {
    case 'color_light':
    case 'dimmable_light':
      return 'bulb';
    case 'onoff_actuator':
      return 'tv';
    case 'curtain':
      return 'curtain';
    case 'door_lock':
      return 'lock';
    case 'siren_actuator':
      return 'siren';
    case 'smoke_alarm':
      return 'smoke';
    case 'ias_sensor':
      return 'motion';
    case 'mmwave_sensor':
      return 'radar';
    case 'multi_sensor':
      return 'sensor';
    case 'button_remote':
      return 'button';
    default:
      return 'device';
  }
}

module.exports = { syncGatewayInventory };
