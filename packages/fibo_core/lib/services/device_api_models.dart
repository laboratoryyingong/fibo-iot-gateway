// Typed models for the agent's REST device API
// (docs/claude-agent/API.md "Data types"). Device ids are aliases such as
// `light.living_room`, never raw hardware ids. `state` keys vary by profile,
// so it is kept as a raw map and read with the typed accessors below.

/// A controllable or sensing device as returned by `GET /devices`.
class AgentDevice {
  const AgentDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.profile,
    required this.room,
    required this.online,
    required this.dangerous,
    required this.state,
  });

  final String id;
  final String name;
  final String type;
  final String profile;
  final String? room;
  final bool online;
  final bool dangerous;
  final Map<String, dynamic> state;

  /// `state.power == "on"`. Null when the profile has no power key (sensors).
  bool? get isOn {
    final power = state['power'];
    if (power is String) return power == 'on';
    if (power is bool) return power;
    return null;
  }

  /// `state.brightness` as a 0–100 int, when present.
  int? get brightness {
    final value = state['brightness'];
    return value is num ? value.round() : null;
  }

  factory AgentDevice.fromJson(Map<String, dynamic> json) {
    return AgentDevice(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      profile: (json['profile'] ?? '').toString(),
      room: json['room']?.toString(),
      online: json['online'] == true,
      dangerous: json['dangerous'] == true,
      state: _mapOf(json['state']),
    );
  }
}

/// A room/grouping as returned by `GET /rooms`.
class AgentRoom {
  const AgentRoom({required this.id, required this.name});

  final String id;
  final String name;

  factory AgentRoom.fromJson(Map<String, dynamic> json) => AgentRoom(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );
}

/// One step of a scene.
class AgentSceneStep {
  const AgentSceneStep({
    required this.deviceId,
    required this.action,
    required this.params,
  });

  final String deviceId;
  final String action;
  final Map<String, dynamic> params;

  factory AgentSceneStep.fromJson(Map<String, dynamic> json) => AgentSceneStep(
        deviceId: (json['device_id'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        params: _mapOf(json['params']),
      );
}

/// A scene as returned by `GET /scenes`.
class AgentScene {
  const AgentScene({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final List<AgentSceneStep> steps;

  factory AgentScene.fromJson(Map<String, dynamic> json) => AgentScene(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        steps: _listOf(json['steps'])
            .map(AgentSceneStep.fromJson)
            .toList(growable: false),
      );
}

/// Result of `POST /devices/:id/control` on success (`200`).
class DeviceControlResult {
  const DeviceControlResult({
    required this.ok,
    required this.deviceId,
    required this.name,
    required this.action,
    required this.previous,
    required this.current,
    required this.converged,
  });

  final bool ok;
  final String deviceId;
  final String name;
  final String action;
  final Map<String, dynamic> previous;
  final Map<String, dynamic> current;
  final bool converged;

  factory DeviceControlResult.fromJson(Map<String, dynamic> json) =>
      DeviceControlResult(
        ok: json['ok'] == true,
        deviceId: (json['device_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        previous: _mapOf(json['previous']),
        current: _mapOf(json['current']),
        // Absent ⇒ treat as converged (matches a plain ok result).
        converged: json['converged'] != false,
      );
}

/// Result of one scene step inside [SceneRunResult].
class SceneStepResult {
  const SceneStepResult({
    required this.step,
    required this.deviceId,
    required this.action,
    required this.ok,
    this.error,
  });

  final int step;
  final String deviceId;
  final String action;
  final bool ok;
  final String? error;

  factory SceneStepResult.fromJson(Map<String, dynamic> json) =>
      SceneStepResult(
        step: (json['step'] as num?)?.toInt() ?? 0,
        deviceId: (json['device_id'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        ok: json['ok'] == true,
        error: json['error']?.toString(),
      );
}

/// Result of `POST /scenes/:id/run`.
class SceneRunResult {
  const SceneRunResult({required this.scene, required this.results});

  final AgentScene scene;
  final List<SceneStepResult> results;

  bool get allOk => results.every((r) => r.ok);

  factory SceneRunResult.fromJson(Map<String, dynamic> json) => SceneRunResult(
        scene: AgentScene.fromJson(_mapOf(json['scene'])),
        results: _listOf(json['results'])
            .map(SceneStepResult.fromJson)
            .toList(growable: false),
      );
}

Map<String, dynamic> _mapOf(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _listOf(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}
