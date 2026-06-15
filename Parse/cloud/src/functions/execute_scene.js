const {
  IoTDataPlaneClient,
  UpdateThingShadowCommand,
} = require('@aws-sdk/client-iot-data-plane');
const { requireHomeContext } = require('../lib/auth');
const { getCloudConfig } = require('../lib/cloud_config');
const { invalidArgument, notFound } = require('../lib/errors');
const { createBusinessId } = require('../lib/ids');

/// Runs a manual scene: writes each `SceneAction`'s deterministic payload to the
/// target device shadow's `desired` state, in order. Logs a `SceneExecution`.
async function executeScene(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['installer', 'admin', 'member'],
  });

  const sceneId = request.params.sceneId;
  if (typeof sceneId !== 'string' || sceneId.trim() === '') {
    throw invalidArgument('`sceneId` is required.');
  }

  const sceneQuery = new Parse.Query('Scene');
  sceneQuery.equalTo('home', home);
  sceneQuery.equalTo('sceneId', sceneId.trim());
  const scene = await sceneQuery.first({ useMasterKey: true });
  if (!scene) {
    throw notFound('Scene was not found in this home.', { sceneId });
  }

  const actionQuery = new Parse.Query('SceneAction');
  actionQuery.equalTo('scene', scene);
  actionQuery.equalTo('status', 'active');
  actionQuery.include('targetDevice');
  actionQuery.ascending('order');
  const actions = await actionQuery.find({ useMasterKey: true });

  const config = getCloudConfig();
  const client = new IoTDataPlaneClient({
    region: config.awsRegion,
    endpoint: `https://${config.iotDataEndpoint}`,
  });

  let successCount = 0;
  let failureCount = 0;
  for (const action of actions) {
    const device = action.get('targetDevice');
    const thingName = device ? device.get('thingName') : null;
    const shadowName = action.get('targetShadowName');
    const payload = action.get('payload');
    if (!thingName || !shadowName || !payload) {
      failureCount += 1;
      continue;
    }
    try {
      await client.send(
        new UpdateThingShadowCommand({
          thingName,
          shadowName,
          payload: Buffer.from(
            JSON.stringify({ state: { desired: payload } })
          ),
        })
      );
      successCount += 1;
    } catch (_) {
      failureCount += 1;
    }
  }

  const now = new Date();
  const status = failureCount === 0 ? 'succeeded' : (successCount > 0 ? 'partial' : 'failed');

  const execution = new Parse.Object('SceneExecution');
  execution.set('executionId', createBusinessId('sx'));
  execution.set('scene', scene);
  execution.set('home', home);
  execution.set('actor', request.user);
  execution.set('mode', request.params.mode === 'automation' ? 'automation' : 'manual');
  execution.set('status', status);
  execution.set('startedAt', now);
  execution.set('completedAt', new Date());
  execution.set('resultSummary', { successCount, failureCount });
  await execution.save(null, { useMasterKey: true });

  scene.set('lastExecutedAt', now);
  await scene.save(null, { useMasterKey: true });

  return {
    execution: {
      executionId: execution.get('executionId'),
      sceneId: scene.get('sceneId'),
      status,
      startedAt: now.toISOString(),
      completedAt: execution.get('completedAt').toISOString(),
    },
    resultSummary: { successCount, failureCount },
  };
}

module.exports = { executeScene };
