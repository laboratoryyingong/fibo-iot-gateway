const { requireHomeContext } = require('../lib/auth');
const { invalidArgument, notFound } = require('../lib/errors');

// Hard-deletes a scene: removes the Scene object and all of its SceneActions.
// Admin/installer only. Use this instead of archiving when the record should be
// physically removed from Parse.
async function deleteScene(request) {
  const { home } = await requireHomeContext({
    user: request.user,
    homeId: request.params.homeId,
    allowedRoles: ['installer', 'admin'],
  });

  const sceneId =
    typeof request.params.sceneId === 'string'
      ? request.params.sceneId.trim()
      : '';
  if (sceneId === '') {
    throw invalidArgument('`sceneId` is required.');
  }

  const sceneQuery = new Parse.Query('Scene');
  sceneQuery.equalTo('home', home);
  sceneQuery.equalTo('sceneId', sceneId);
  const scene = await sceneQuery.first({ useMasterKey: true });
  if (!scene) {
    throw notFound('Scene was not found in this home.', { sceneId });
  }

  const actionQuery = new Parse.Query('SceneAction');
  actionQuery.equalTo('scene', scene);
  const actions = await actionQuery.find({ useMasterKey: true });
  if (actions.length > 0) {
    await Parse.Object.destroyAll(actions, { useMasterKey: true });
  }

  await scene.destroy({ useMasterKey: true });

  return { deletedSceneId: sceneId };
}

module.exports = { deleteScene };
