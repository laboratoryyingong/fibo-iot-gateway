import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// One device action in a scene draft: the target device + the deterministic
/// state to write (e.g. `{power: 1, level: 40}`).
class SceneActionDraft {
  SceneActionDraft({required this.endpointKey, required this.state});

  final String endpointKey;
  Map<String, dynamic> state;
}

/// Loads a scene's ordered actions for editing (`getSceneDetail`).
Future<List<SceneActionDraft>> fetchSceneActions(
  String homeId,
  String sceneId,
) async {
  final fn = ParseCloudFunction('getSceneDetail');
  final resp =
      await fn.execute(parameters: {'homeId': homeId, 'sceneId': sceneId});
  if (!resp.success || resp.result is! Map) {
    throw Exception('getSceneDetail failed: ${resp.error?.message}');
  }
  final result = (resp.result as Map).cast<String, dynamic>();
  final actions = <SceneActionDraft>[];
  for (final raw in (result['actions'] as List? ?? const [])) {
    if (raw is! Map) continue;
    final a = raw.cast<String, dynamic>();
    final ek = a['targetEndpointKey']?.toString();
    if (ek == null || ek.isEmpty) continue;
    final payload = (a['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
    final state = (payload['state'] as Map?)?.cast<String, dynamic>() ?? const {};
    actions.add(SceneActionDraft(endpointKey: ek, state: Map.of(state)));
  }
  return actions;
}

/// Creates or updates a scene + replaces its actions (`upsertScene`). Requires
/// at least one action. Pass [sceneId] to update, or null to create.
Future<void> saveScene({
  required String homeId,
  String? sceneId,
  required String name,
  required String icon,
  required List<SceneActionDraft> actions,
  String status = 'active',
}) async {
  final scene = <String, dynamic>{
    'name': name,
    'icon': icon,
    'enabled': true,
    'executionMode': 'manual_only',
    'status': status,
  };
  if (sceneId != null) scene['sceneId'] = sceneId;
  final fn = ParseCloudFunction('upsertScene');
  final resp = await fn.execute(parameters: {
    'homeId': homeId,
    'scene': scene,
    'actions': [
      for (var i = 0; i < actions.length; i++)
        {
          'order': (i + 1) * 10,
          'targetEndpointKey': actions[i].endpointKey,
          'actionType': 'desired_state',
          'payload': {'state': actions[i].state},
        },
    ],
  });
  if (!resp.success) {
    throw Exception('upsertScene failed: ${resp.error?.message}');
  }
}

/// Hard-deletes a scene and its actions from Parse (`deleteScene`).
Future<void> deleteScene({
  required String homeId,
  required String sceneId,
}) async {
  final fn = ParseCloudFunction('deleteScene');
  final resp =
      await fn.execute(parameters: {'homeId': homeId, 'sceneId': sceneId});
  if (!resp.success) {
    throw Exception('deleteScene failed: ${resp.error?.message}');
  }
}
