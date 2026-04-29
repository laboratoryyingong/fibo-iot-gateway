const { requireHomeContext } = require('../lib/auth');
const {
  serializeDevice,
  serializeGateway,
  serializeScene,
  serializeSpace,
} = require('../lib/serialize');

async function listHomeGraph(request) {
  const includeArchived = request.params.includeArchived === true;
  const { home, membership, role } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
  });

  const gatewayQuery = new Parse.Query('Gateway');
  gatewayQuery.equalTo('home', home);
  if (!includeArchived) {
    gatewayQuery.notEqualTo('status', 'archived');
  }
  gatewayQuery.ascending('displayName');

  const spaceQuery = new Parse.Query('Space');
  spaceQuery.equalTo('home', home);
  if (!includeArchived) {
    spaceQuery.equalTo('status', 'active');
  }
  spaceQuery.ascending('sortOrder');

  const deviceQuery = new Parse.Query('DeviceEndpoint');
  deviceQuery.equalTo('home', home);
  if (!includeArchived) {
    deviceQuery.notEqualTo('status', 'deleted');
  }
  deviceQuery.include(['gateway', 'space']);
  deviceQuery.ascending('sortOrder');

  const sceneQuery = new Parse.Query('Scene');
  sceneQuery.equalTo('home', home);
  if (!includeArchived) {
    sceneQuery.equalTo('status', 'active');
  }
  sceneQuery.descending('updatedAt');

  const [gateways, spaces, devices, scenes] = await Promise.all([
    gatewayQuery.find({ useMasterKey: true }),
    spaceQuery.find({ useMasterKey: true }),
    deviceQuery.find({ useMasterKey: true }),
    sceneQuery.find({ useMasterKey: true }),
  ]);

  const sceneActionCounts = await loadSceneActionCounts(home, scenes);

  return {
    home: {
      homeId: home.get('homeId'),
      name: home.get('name'),
      timezone: home.get('timezone'),
    },
    membership: {
      role,
      status: membership.get('status'),
    },
    gateways: gateways.map(serializeGateway),
    spaces: spaces.map(serializeSpace),
    devices: devices.map(serializeDevice),
    scenes: scenes.map((scene) => serializeScene(scene, sceneActionCounts)),
  };
}

async function loadSceneActionCounts(home, scenes) {
  if (scenes.length === 0) {
    return new Map();
  }

  const actionQuery = new Parse.Query('SceneAction');
  actionQuery.equalTo('home', home);
  actionQuery.containedIn('scene', scenes);
  actionQuery.equalTo('status', 'active');
  actionQuery.include('scene');

  const actions = await actionQuery.find({ useMasterKey: true });
  const counts = new Map();
  for (const action of actions) {
    const scene = action.get('scene');
    if (!scene) {
      continue;
    }

    counts.set(scene.id, (counts.get(scene.id) || 0) + 1);
  }

  return counts;
}
module.exports = { listHomeGraph };
