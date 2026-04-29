function serializeGateway(gateway) {
  return {
    gatewayId: gateway.get('gatewayId'),
    thingName: gateway.get('thingName'),
    displayName: gateway.get('displayName'),
    statusSummary: gateway.get('statusSummary') || null,
    firmwareVersion: gateway.get('firmwareVersion') || null,
  };
}

function serializeSpace(space) {
  return {
    spaceId: space.get('spaceId'),
    name: space.get('name'),
    imageUrl: space.get('imageUrl') || null,
    sortOrder: space.get('sortOrder') || 0,
    status: space.get('status'),
  };
}

function serializeDevice(device) {
  const gateway = device.get('gateway');
  const space = device.get('space');

  return {
    endpointKey: device.get('endpointKey'),
    gatewayId: gateway ? gateway.get('gatewayId') : null,
    spaceId: space ? space.get('spaceId') : null,
    thingName: device.get('thingName'),
    shadowName: device.get('shadowName'),
    profile: device.get('profile'),
    displayName: device.get('displayName'),
    iconKey: device.get('iconKey') || null,
    lastKnownOnline: device.get('lastKnownOnline'),
    lastKnownState: device.get('lastKnownState') || null,
    sortOrder: device.get('sortOrder') || 0,
    status: device.get('status'),
  };
}

function serializeScene(scene, actionCounts) {
  return {
    sceneId: scene.get('sceneId'),
    name: scene.get('name'),
    icon: scene.get('icon') || null,
    enabled: scene.get('enabled') !== false,
    executionMode: scene.get('executionMode'),
    status: scene.get('status'),
    actionCount: actionCounts ? actionCounts.get(scene.id) || 0 : 0,
    lastExecutedAt: scene.get('lastExecutedAt') || null,
  };
}

function serializeSceneAction(action) {
  const targetDevice = action.get('targetDevice');
  return {
    order: action.get('order') || 0,
    targetEndpointKey: targetDevice ? targetDevice.get('endpointKey') : null,
    targetShadowName: action.get('targetShadowName'),
    actionType: action.get('actionType'),
    payload: action.get('payload') || null,
    status: action.get('status'),
  };
}

module.exports = {
  serializeDevice,
  serializeGateway,
  serializeScene,
  serializeSceneAction,
  serializeSpace,
};
