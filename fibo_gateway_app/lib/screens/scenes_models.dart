import 'package:flutter/material.dart';

enum SceneFlowType { trigger, action }

class SceneDetailArgs {
  const SceneDetailArgs(this.sceneId);

  final String sceneId;
}

class SceneFlowArgs {
  const SceneFlowArgs({required this.sceneId, required this.type});

  final String sceneId;
  final SceneFlowType type;
}

class SceneSelectDeviceArgs {
  const SceneSelectDeviceArgs({
    required this.sceneId,
    required this.type,
    required this.templateId,
  });

  final String sceneId;
  final SceneFlowType type;
  final String templateId;
}

class SceneDevice {
  const SceneDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.status,
    required this.icon,
  });

  final String id;
  final String name;
  final String room;
  final String status;
  final IconData icon;
}

class SceneStep {
  const SceneStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class SceneTemplate {
  const SceneTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.requiresDevice = false,
    this.sceneStepVerb,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool requiresDevice;
  final String? sceneStepVerb;
}

class SceneItem {
  const SceneItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.deviceIds,
    required this.triggers,
    required this.actions,
    this.featured = false,
    this.active = true,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> deviceIds;
  final List<SceneStep> triggers;
  final List<SceneStep> actions;
  final bool featured;
  final bool active;

  SceneItem copyWith({
    String? id,
    String? name,
    String? emoji,
    List<String>? deviceIds,
    List<SceneStep>? triggers,
    List<SceneStep>? actions,
    bool? featured,
    bool? active,
  }) {
    return SceneItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      deviceIds: deviceIds ?? this.deviceIds,
      triggers: triggers ?? this.triggers,
      actions: actions ?? this.actions,
      featured: featured ?? this.featured,
      active: active ?? this.active,
    );
  }
}

class ScenesMockStore extends ChangeNotifier {
  ScenesMockStore._();

  static final ScenesMockStore instance = ScenesMockStore._();

  final List<SceneDevice> devices = const [
    SceneDevice(
      id: 'dev-1',
      name: 'Temperature Sensor',
      room: 'Living Room',
      status: '24°C • Online',
      icon: Icons.thermostat,
    ),
    SceneDevice(
      id: 'dev-2',
      name: 'Air Conditioner',
      room: 'Living Room',
      status: 'Off • Online',
      icon: Icons.ac_unit,
    ),
    SceneDevice(
      id: 'dev-3',
      name: 'Ceiling Light',
      room: 'Living Room',
      status: 'On • 70% brightness',
      icon: Icons.lightbulb,
    ),
    SceneDevice(
      id: 'dev-4',
      name: 'Door Sensor',
      room: 'Bedroom',
      status: 'Closed • Online',
      icon: Icons.sensors,
    ),
    SceneDevice(
      id: 'dev-5',
      name: 'Curtain Motor',
      room: 'Bedroom',
      status: 'Open • Online',
      icon: Icons.view_sidebar,
    ),
    SceneDevice(
      id: 'dev-6',
      name: 'Smart Speaker',
      room: 'Studio',
      status: 'Idle • Online',
      icon: Icons.speaker,
    ),
    SceneDevice(
      id: 'dev-7',
      name: 'Security Camera',
      room: 'Entrance',
      status: 'Recording • Online',
      icon: Icons.videocam,
    ),
    SceneDevice(
      id: 'dev-8',
      name: 'Window Sensor',
      room: 'Kitchen',
      status: 'Closed • Online',
      icon: Icons.window,
    ),
  ];

  final List<SceneTemplate> triggerTemplates = const [
    SceneTemplate(
      id: 'trigger-device-state',
      title: 'Device State',
      description: 'Trigger when a device state changes',
      icon: Icons.devices_other,
      requiresDevice: true,
      sceneStepVerb: 'changes state',
    ),
    SceneTemplate(
      id: 'trigger-schedule',
      title: 'Schedule',
      description: 'Trigger at a specific time or interval',
      icon: Icons.schedule,
      sceneStepVerb: 'At 10:00 PM every day',
    ),
    SceneTemplate(
      id: 'trigger-location',
      title: 'Location',
      description: 'Geofence-based trigger',
      icon: Icons.location_on_outlined,
      sceneStepVerb: 'When arriving home',
    ),
    SceneTemplate(
      id: 'trigger-manual',
      title: 'Manual',
      description: 'Trigger manually with a button tap',
      icon: Icons.touch_app_outlined,
      sceneStepVerb: 'Tap to run manually',
    ),
  ];

  final List<SceneTemplate> actionTemplates = const [
    SceneTemplate(
      id: 'action-control-device',
      title: 'Control Device',
      description: 'Control a device\'s state or settings',
      icon: Icons.tune,
      requiresDevice: true,
      sceneStepVerb: 'Set to preferred mode',
    ),
    SceneTemplate(
      id: 'action-send-notification',
      title: 'Send Notification',
      description: 'Push a notification to your devices',
      icon: Icons.notifications_active,
      sceneStepVerb: 'Send push notification',
    ),
    SceneTemplate(
      id: 'action-delay',
      title: 'Delay',
      description: 'Pause before running the next action',
      icon: Icons.hourglass_bottom,
      sceneStepVerb: 'Wait for 5 minutes',
    ),
    SceneTemplate(
      id: 'action-run-scene',
      title: 'Run Scene',
      description: 'Trigger another scene as a step',
      icon: Icons.bolt,
      sceneStepVerb: 'Run Movie scene',
    ),
  ];

  final List<String> emojis = const [
    '☀️',
    '🌗',
    '🥁',
    '🍿',
    '🔒',
    '🌅',
    '🏃',
    '🛌',
  ];

  List<SceneItem> _scenes = [
    SceneItem(
      id: 'scene-1',
      name: 'Mornin’',
      emoji: '☀️',
      featured: true,
      active: true,
      deviceIds: const ['dev-1', 'dev-2', 'dev-3', 'dev-5', 'dev-6'],
      triggers: const [
        SceneStep(
          id: 'trigger-1',
          title: 'Temperature Sensor',
          subtitle: 'Less than 24°C',
          icon: Icons.thermostat,
        ),
      ],
      actions: const [
        SceneStep(
          id: 'action-2',
          title: 'Notification',
          subtitle: 'Send push notification',
          icon: Icons.notifications_active,
        ),
        SceneStep(
          id: 'action-1',
          title: 'Air Conditioner',
          subtitle: 'Turn On → Heat Mode 26°C',
          icon: Icons.ac_unit,
        ),
      ],
    ),
    SceneItem(
      id: 'scene-2',
      name: 'Night',
      emoji: '🌗',
      active: true,
      deviceIds: const ['dev-2', 'dev-3', 'dev-4', 'dev-7', 'dev-8'],
      triggers: const [
        SceneStep(
          id: 'trigger-3',
          title: 'Schedule',
          subtitle: 'Every day at 10:00 PM',
          icon: Icons.schedule,
        ),
      ],
      actions: const [
        SceneStep(
          id: 'action-3',
          title: 'Ceiling Light',
          subtitle: 'Dim lights to 20%',
          icon: Icons.lightbulb,
        ),
      ],
    ),
    SceneItem(
      id: 'scene-3',
      name: 'Music',
      emoji: '🥁',
      active: true,
      deviceIds: const ['dev-3', 'dev-5', 'dev-6', 'dev-7', 'dev-8'],
      triggers: const [
        SceneStep(
          id: 'trigger-4',
          title: 'Manual',
          subtitle: 'Tap to run manually',
          icon: Icons.touch_app_outlined,
        ),
      ],
      actions: const [
        SceneStep(
          id: 'action-4',
          title: 'Smart Speaker',
          subtitle: 'Play playlist in Studio',
          icon: Icons.speaker,
        ),
      ],
    ),
    SceneItem(
      id: 'scene-4',
      name: 'Movie',
      emoji: '🍿',
      active: false,
      deviceIds: const ['dev-2', 'dev-3', 'dev-5', 'dev-6', 'dev-7'],
      triggers: const [
        SceneStep(
          id: 'trigger-5',
          title: 'Manual',
          subtitle: 'Tap to run manually',
          icon: Icons.touch_app_outlined,
        ),
      ],
      actions: const [
        SceneStep(
          id: 'action-5',
          title: 'Ceiling Light',
          subtitle: 'Dim lights to 10%',
          icon: Icons.lightbulb,
        ),
      ],
    ),
    SceneItem(
      id: 'scene-5',
      name: 'Leave',
      emoji: '🔒',
      active: false,
      deviceIds: const ['dev-4', 'dev-7', 'dev-8', 'dev-2', 'dev-3'],
      triggers: const [
        SceneStep(
          id: 'trigger-6',
          title: 'Location',
          subtitle: 'When leaving home',
          icon: Icons.location_on_outlined,
        ),
      ],
      actions: const [
        SceneStep(
          id: 'action-6',
          title: 'Security Camera',
          subtitle: 'Enable surveillance mode',
          icon: Icons.videocam,
        ),
      ],
    ),
  ];

  int _sceneSeed = 100;
  int _stepSeed = 1000;

  List<SceneItem> get scenes => List.unmodifiable(_scenes);

  SceneItem? findScene(String id) {
    for (final scene in _scenes) {
      if (scene.id == id) {
        return scene;
      }
    }
    return null;
  }

  String deviceSummary(SceneItem scene) {
    final count = scene.deviceIds.length;
    if (scene.featured) {
      return '$count devices are on';
    }
    return '$count devices active';
  }

  Map<String, List<SceneDevice>> get devicesByRoom {
    final grouped = <String, List<SceneDevice>>{};
    for (final device in devices) {
      grouped.putIfAbsent(device.room, () => []).add(device);
    }
    return grouped;
  }

  List<SceneDevice> devicesForScene(SceneItem scene) {
    final ids = scene.deviceIds.toSet();
    return devices.where((device) => ids.contains(device.id)).toList();
  }

  void saveSceneBasics({
    required String sceneId,
    required String name,
    required String emoji,
  }) {
    final index = _scenes.indexWhere((element) => element.id == sceneId);
    if (index < 0) return;
    _scenes[index] = _scenes[index].copyWith(
      name: name.trim().isEmpty ? _scenes[index].name : name.trim(),
      emoji: emoji,
    );
    notifyListeners();
  }

  String createScene({
    required String name,
    required String emoji,
    required List<String> deviceIds,
  }) {
    final newId = 'scene-${_sceneSeed++}';
    final normalizedName = name.trim().isEmpty ? 'New Scene' : name.trim();
    final uniqueDeviceIds = deviceIds.toSet().toList();
    _scenes = [
      ..._scenes,
      SceneItem(
        id: newId,
        name: normalizedName,
        emoji: emoji,
        deviceIds: uniqueDeviceIds,
        triggers: const [],
        actions: const [],
        featured: false,
        active: true,
      ),
    ];
    notifyListeners();
    return newId;
  }

  void deleteScene(String sceneId) {
    _scenes = _scenes.where((scene) => scene.id != sceneId).toList();
    notifyListeners();
  }

  void activateScene(String sceneId) {
    final index = _scenes.indexWhere((scene) => scene.id == sceneId);
    if (index < 0) return;
    final scene = _scenes[index];
    _scenes[index] = scene.copyWith(active: true);
    notifyListeners();
  }

  void addStepFromTemplate({
    required String sceneId,
    required SceneFlowType type,
    required String templateId,
    String? deviceId,
  }) {
    final sceneIndex = _scenes.indexWhere((scene) => scene.id == sceneId);
    if (sceneIndex < 0) return;

    final scene = _scenes[sceneIndex];
    final templates = type == SceneFlowType.trigger
        ? triggerTemplates
        : actionTemplates;
    SceneTemplate? template;
    for (final item in templates) {
      if (item.id == templateId) {
        template = item;
        break;
      }
    }
    if (template == null) return;

    SceneDevice? device;
    if (template.requiresDevice && deviceId != null) {
      for (final item in devices) {
        if (item.id == deviceId) {
          device = item;
          break;
        }
      }
    }

    final title = device?.name ?? template.title;
    final subtitle = device != null
        ? (template.sceneStepVerb == null
              ? device.status
              : '${device.status} • ${template.sceneStepVerb}')
        : (template.sceneStepVerb ?? template.description);

    final step = SceneStep(
      id: 'step-${_stepSeed++}',
      title: title,
      subtitle: subtitle,
      icon: device?.icon ?? template.icon,
    );

    final nextDeviceIds = scene.deviceIds.toSet();
    if (device?.id != null) {
      nextDeviceIds.add(device!.id);
    }

    _scenes[sceneIndex] = scene.copyWith(
      deviceIds: nextDeviceIds.toList(),
      triggers: type == SceneFlowType.trigger
          ? [...scene.triggers, step]
          : null,
      actions: type == SceneFlowType.action ? [...scene.actions, step] : null,
    );

    notifyListeners();
  }
}
