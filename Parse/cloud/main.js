const { assignDeviceToSpace } = require('./src/functions/assign_device_to_space');
const { getAwsIotSession } = require('./src/functions/get_aws_iot_session');
const { getSceneDetail } = require('./src/functions/get_scene_detail');
const { listHomeGraph } = require('./src/functions/list_home_graph');
const { upsertScene } = require('./src/functions/upsert_scene');

Parse.Cloud.define('assignDeviceToSpace', assignDeviceToSpace);
Parse.Cloud.define('getAwsIotSession', getAwsIotSession);
Parse.Cloud.define('getSceneDetail', getSceneDetail);
Parse.Cloud.define('listHomeGraph', listHomeGraph);
Parse.Cloud.define('upsertScene', upsertScene);
