import 'package:flutter/material.dart';

import '../services/mock_room_photo_catalog.dart';
import 'space_device_types.dart';

class SpaceRoom {
  const SpaceRoom({
    required this.id,
    required this.name,
    required this.devices,
    this.imageUrl,
  });

  final String id;
  final String name;
  final List<SpaceDeviceState> devices;
  final String? imageUrl;

  int get onCount => devices.where((device) => device.isOn).length;
  int get totalCount => devices.length;
  String get onSummary => '$onCount/$totalCount is on';

  SpaceRoom copyWith({
    String? id,
    String? name,
    List<SpaceDeviceState>? devices,
    String? imageUrl,
  }) {
    return SpaceRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      devices: devices ?? this.devices,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class SpaceDeviceState {
  const SpaceDeviceState({
    required this.id,
    required this.name,
    required this.icon,
    required this.controlType,
    required this.isOn,
    this.valueLabel,
  });

  final String id;
  final String name;
  final IconData icon;
  final SpaceDeviceControlType controlType;
  final bool isOn;
  final String? valueLabel;

  SpaceDeviceState copyWith({
    String? id,
    String? name,
    IconData? icon,
    SpaceDeviceControlType? controlType,
    bool? isOn,
    String? valueLabel,
  }) {
    return SpaceDeviceState(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      controlType: controlType ?? this.controlType,
      isOn: isOn ?? this.isOn,
      valueLabel: valueLabel ?? this.valueLabel,
    );
  }
}

class SpaceDeviceTemplate {
  const SpaceDeviceTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.controlType,
    this.valueLabel,
  });

  final String id;
  final String name;
  final IconData icon;
  final SpaceDeviceControlType controlType;
  final String? valueLabel;
}

class SpaceMockStore extends ChangeNotifier {
  SpaceMockStore._() {
    _rooms = _buildInitialRooms();
  }

  static final SpaceMockStore instance = SpaceMockStore._();

  final List<SpaceDeviceTemplate> _templates = const [
    SpaceDeviceTemplate(
      id: 'tpl-climate',
      name: 'Climate',
      icon: Icons.thermostat_outlined,
      controlType: SpaceDeviceControlType.climate,
      valueLabel: '17°C',
    ),
    SpaceDeviceTemplate(
      id: 'tpl-fan',
      name: 'Fan',
      icon: Icons.mode_fan_off_outlined,
      controlType: SpaceDeviceControlType.fan,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-purifier',
      name: 'Purifier',
      icon: Icons.air_outlined,
      controlType: SpaceDeviceControlType.purifier,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-ac',
      name: 'Air Conditioner',
      icon: Icons.ac_unit_outlined,
      controlType: SpaceDeviceControlType.ac,
      valueLabel: '24°C',
    ),
    SpaceDeviceTemplate(
      id: 'tpl-ceiling',
      name: 'Ceiling Light',
      icon: Icons.lightbulb_outline,
      controlType: SpaceDeviceControlType.ceilingLight,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-bulb',
      name: 'Bulb',
      icon: Icons.tungsten_outlined,
      controlType: SpaceDeviceControlType.bulb,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-tv',
      name: 'Television',
      icon: Icons.tv_outlined,
      controlType: SpaceDeviceControlType.climate,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-speaker',
      name: 'Speakers',
      icon: Icons.speaker_outlined,
      controlType: SpaceDeviceControlType.speaker,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-washer',
      name: 'Washing Machine',
      icon: Icons.local_laundry_service_outlined,
      controlType: SpaceDeviceControlType.climate,
    ),
    SpaceDeviceTemplate(
      id: 'tpl-oven',
      name: 'Oven',
      icon: Icons.microwave_outlined,
      controlType: SpaceDeviceControlType.climate,
    ),
  ];

  late List<SpaceRoom> _rooms;
  int _nextRoomId = 5;
  int _nextDeviceId = 1;

  List<SpaceRoom> get rooms => List.unmodifiable(_rooms);
  List<SpaceDeviceTemplate> get deviceTemplates =>
      List.unmodifiable(_templates);

  int get totalDevices {
    return _rooms.fold<int>(0, (sum, room) => sum + room.devices.length);
  }

  List<SpaceDeviceState> get allDevices {
    return _rooms.expand((room) => room.devices).toList(growable: false);
  }

  Map<String, int> get deviceNameCounts {
    final counts = <String, int>{};
    for (final device in allDevices) {
      counts.update(device.name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  SpaceRoom? findRoomById(String roomId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  ({SpaceRoom room, SpaceDeviceState device})? findDeviceByIds({
    required String roomId,
    required String deviceId,
  }) {
    final room = findRoomById(roomId);
    if (room == null) return null;
    for (final device in room.devices) {
      if (device.id == deviceId) {
        return (room: room, device: device);
      }
    }
    return null;
  }

  ({SpaceRoom room, SpaceDeviceState device})? findFirstDeviceByType(
    SpaceDeviceControlType type,
  ) {
    for (final room in _rooms) {
      for (final device in room.devices) {
        if (device.controlType == type) {
          return (room: room, device: device);
        }
      }
    }
    return null;
  }

  ({SpaceRoom room, SpaceDeviceState device})? findFirstDeviceByName(
    String name,
  ) {
    for (final room in _rooms) {
      for (final device in room.devices) {
        if (device.name == name) {
          return (room: room, device: device);
        }
      }
    }
    return null;
  }

  void toggleDevicePower({
    required String roomId,
    required String deviceId,
    bool? value,
  }) {
    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex < 0) return;
    final room = _rooms[roomIndex];
    final deviceIndex = room.devices.indexWhere(
      (device) => device.id == deviceId,
    );
    if (deviceIndex < 0) return;

    final device = room.devices[deviceIndex];
    final nextValue = value ?? !device.isOn;
    if (nextValue == device.isOn) return;

    final updatedDevice = device.copyWith(isOn: nextValue);
    final updatedDevices = [...room.devices]..[deviceIndex] = updatedDevice;
    final updatedRoom = room.copyWith(devices: updatedDevices);
    _rooms = [..._rooms]..[roomIndex] = updatedRoom;
    notifyListeners();
  }

  SpaceRoom? addRoom({
    required String name,
    required List<String> templateIds,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || templateIds.isEmpty) return null;

    final devices = <SpaceDeviceState>[];
    for (final templateId in templateIds) {
      final template = _templates
          .where((item) => item.id == templateId)
          .firstOrNull;
      if (template == null) continue;
      devices.add(_createDeviceFromTemplate(template, isOn: false));
    }

    if (devices.isEmpty) return null;

    final newRoom = SpaceRoom(
      id: 'room-${_nextRoomId++}',
      name: trimmedName,
      devices: devices,
      imageUrl: roomPhotoUrlForName(trimmedName),
    );
    _rooms = [..._rooms, newRoom];
    notifyListeners();
    return newRoom;
  }

  List<SpaceRoom> _buildInitialRooms() {
    return [
      SpaceRoom(
        id: 'room-1',
        name: 'Living Room',
        imageUrl: kLivingRoomPhotoUrl,
        devices: [
          _createDeviceFromTemplateById(
            'tpl-climate',
            isOn: true,
            valueLabel: '17°C',
          ),
          _createDeviceFromTemplateById('tpl-fan', isOn: false),
          _createDeviceFromTemplateById('tpl-purifier', isOn: false),
          _createDeviceFromTemplateById(
            'tpl-ac',
            isOn: true,
            valueLabel: '24°C',
          ),
          _createDeviceFromTemplateById('tpl-ceiling', isOn: true),
        ],
      ),
      SpaceRoom(
        id: 'room-2',
        name: 'Bedroom',
        imageUrl: kBedroomPhotoUrl,
        devices: [
          _createDeviceFromTemplateById('tpl-ceiling', isOn: false),
          _createDeviceFromTemplateById('tpl-tv', isOn: false),
          _createDeviceFromTemplateById('tpl-bulb', isOn: false),
          _createDeviceFromTemplateById(
            'tpl-climate',
            isOn: false,
            valueLabel: '19°C',
          ),
        ],
      ),
      SpaceRoom(
        id: 'room-3',
        name: 'Kitchen',
        imageUrl: kKitchenPhotoUrl,
        devices: [
          _createDeviceFromTemplateById('tpl-ceiling', isOn: true),
          _createDeviceFromTemplateById('tpl-oven', isOn: false),
          _createDeviceFromTemplateById('tpl-purifier', isOn: true),
          _createDeviceFromTemplateById('tpl-fan', isOn: true),
          _createDeviceFromTemplateById(
            'tpl-climate',
            isOn: false,
            valueLabel: '20°C',
          ),
          _createDeviceFromTemplateById(
            'tpl-ac',
            isOn: false,
            valueLabel: '25°C',
          ),
        ],
      ),
      SpaceRoom(
        id: 'room-4',
        name: 'Office',
        imageUrl: kOfficePhotoUrl,
        devices: [
          _createDeviceFromTemplateById('tpl-ceiling', isOn: true),
          _createDeviceFromTemplateById('tpl-speaker', isOn: false),
          _createDeviceFromTemplateById(
            'tpl-climate',
            isOn: false,
            valueLabel: '21°C',
          ),
          _createDeviceFromTemplateById('tpl-fan', isOn: false),
        ],
      ),
    ];
  }

  SpaceDeviceState _createDeviceFromTemplateById(
    String templateId, {
    required bool isOn,
    String? valueLabel,
  }) {
    final template = _templates.firstWhere((item) => item.id == templateId);
    return _createDeviceFromTemplate(
      template,
      isOn: isOn,
      valueLabel: valueLabel,
    );
  }

  SpaceDeviceState _createDeviceFromTemplate(
    SpaceDeviceTemplate template, {
    required bool isOn,
    String? valueLabel,
  }) {
    return SpaceDeviceState(
      id: 'device-${_nextDeviceId++}',
      name: template.name,
      icon: template.icon,
      controlType: template.controlType,
      isOn: isOn,
      valueLabel: valueLabel ?? template.valueLabel,
    );
  }
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
