const { requireHomeContext } = require('../lib/auth');
const { invalidArgument, notFound } = require('../lib/errors');
const { serializeSceneAction } = require('../lib/serialize');

async function getSceneDetail(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
  });

  const sceneId = request.params.sceneId;
  if (typeof sceneId !== 'string' || sceneId.trim() === '') {
    throw invalidArgument('`sceneId` must be a non-empty string.');
  }

  const sceneQuery = new Parse.Query('Scene');
  sceneQuery.equalTo('home', home);
  sceneQuery.equalTo('sceneId', sceneId.trim());
  const scene = await sceneQuery.first({ useMasterKey: true });
  if (!scene) {
    throw notFound('Scene was not found in this home.', { sceneId: sceneId.trim() });
  }

  const actionQuery = new Parse.Query('SceneAction');
  actionQuery.equalTo('scene', scene);
  actionQuery.equalTo('status', 'active');
  actionQuery.include('targetDevice');
  actionQuery.ascending('order');
  const actions = await actionQuery.find({ useMasterKey: true });

  return {
    scene: {
      sceneId: scene.get('sceneId'),
      name: scene.get('name'),
      icon: scene.get('icon') || null,
      enabled: scene.get('enabled') !== false,
      executionMode: scene.get('executionMode'),
      status: scene.get('status'),
    },
    actions: actions.map(serializeSceneAction),
  };
}

module.exports = { getSceneDetail };
