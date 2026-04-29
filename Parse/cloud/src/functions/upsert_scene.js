const { requireHomeContext } = require('../lib/auth');
const { conflict, invalidArgument, notFound } = require('../lib/errors');
const { createBusinessId } = require('../lib/ids');
const {
  validateActionAgainstDevice,
  validateSceneInput,
} = require('../lib/scene_validation');

async function upsertScene(request) {
  const { home, role } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['installer', 'admin'],
  });

  const normalized = validateSceneInput(request.params);
  const sceneObject = await loadOrCreateScene({
    home,
    user: request.user,
    sceneInput: normalized.scene,
  });

  const devicesByEndpointKey = await loadTargetDevices(home, normalized.actions);
  for (const action of normalized.actions) {
    const device = devicesByEndpointKey.get(action.targetEndpointKey);
    if (!device) {
      throw notFound('Target device was not found in this home.', {
        endpointKey: action.targetEndpointKey,
      });
    }
    validateActionAgainstDevice(action, device);
  }

  sceneObject.set('name', normalized.scene.name);
  sceneObject.set('icon', normalized.scene.icon);
  sceneObject.set('enabled', normalized.scene.enabled);
  sceneObject.set('executionMode', normalized.scene.executionMode);
  sceneObject.set('status', normalized.scene.status);
  sceneObject.set('updatedBy', request.user);
  if (!sceneObject.get('createdBy')) {
    sceneObject.set('createdBy', request.user);
  }

  await sceneObject.save(null, { useMasterKey: true });
  await replaceSceneActions({
    home,
    scene: sceneObject,
    actions: normalized.actions,
    devicesByEndpointKey,
  });

  return {
    scene: {
      sceneId: sceneObject.get('sceneId'),
      name: sceneObject.get('name'),
      enabled: sceneObject.get('enabled') !== false,
      executionMode: sceneObject.get('executionMode'),
      status: sceneObject.get('status'),
      actionCount: normalized.actions.length,
      updatedAt: sceneObject.updatedAt ? sceneObject.updatedAt.toISOString() : null,
      updatedByRole: role,
    },
  };
}

async function loadOrCreateScene({ home, user, sceneInput }) {
  if (!sceneInput.sceneId) {
    const scene = new Parse.Object('Scene');
    scene.set('sceneId', createBusinessId('scene'));
    scene.set('home', home);
    scene.set('createdBy', user);
    return scene;
  }

  const sceneQuery = new Parse.Query('Scene');
  sceneQuery.equalTo('home', home);
  sceneQuery.equalTo('sceneId', sceneInput.sceneId);
  const scene = await sceneQuery.first({ useMasterKey: true });
  if (!scene) {
    throw notFound('Scene was not found in this home.', {
      sceneId: sceneInput.sceneId,
    });
  }

  return scene;
}

async function loadTargetDevices(home, actions) {
  const endpointKeys = [...new Set(actions.map((action) => action.targetEndpointKey))];
  if (endpointKeys.length === 0) {
    throw invalidArgument('Scene must contain at least one target device.');
  }

  const deviceQuery = new Parse.Query('DeviceEndpoint');
  deviceQuery.equalTo('home', home);
  deviceQuery.containedIn('endpointKey', endpointKeys);
  const devices = await deviceQuery.find({ useMasterKey: true });

  const byEndpointKey = new Map();
  for (const device of devices) {
    byEndpointKey.set(device.get('endpointKey'), device);
  }

  return byEndpointKey;
}

async function replaceSceneActions({ home, scene, actions, devicesByEndpointKey }) {
  const existingQuery = new Parse.Query('SceneAction');
  existingQuery.equalTo('scene', scene);
  const existing = await existingQuery.find({ useMasterKey: true });

  if (existing.length > 0) {
    await Parse.Object.destroyAll(existing, { useMasterKey: true });
  }

  const nextActions = [];
  const orderSet = new Set();
  for (const action of actions) {
    if (orderSet.has(action.order)) {
      throw conflict('Scene action order values must be unique.', {
        order: action.order,
      });
    }
    orderSet.add(action.order);

    const device = devicesByEndpointKey.get(action.targetEndpointKey);
    const sceneAction = new Parse.Object('SceneAction');
    sceneAction.set('scene', scene);
    sceneAction.set('home', home);
    sceneAction.set('order', action.order);
    sceneAction.set('targetDevice', device);
    sceneAction.set('targetShadowName', device.get('shadowName'));
    sceneAction.set('actionType', action.actionType);
    sceneAction.set('payload', action.payload);
    sceneAction.set('status', 'active');
    nextActions.push(sceneAction);
  }

  if (nextActions.length > 0) {
    await Parse.Object.saveAll(nextActions, { useMasterKey: true });
  }
}

module.exports = { upsertScene };
