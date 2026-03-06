enum SpaceDeviceControlType {
  climate,
  fan,
  ac,
  purifier,
  speaker,
  ceilingLight,
  bulb,
}

class SpaceDeviceControlArgs {
  const SpaceDeviceControlArgs({
    required this.type,
    this.roomId,
    this.deviceId,
    this.deviceName,
  });

  final SpaceDeviceControlType type;
  final String? roomId;
  final String? deviceId;
  final String? deviceName;

  SpaceDeviceControlArgs copyWith({
    SpaceDeviceControlType? type,
    String? roomId,
    String? deviceId,
    String? deviceName,
  }) {
    return SpaceDeviceControlArgs(
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}

extension SpaceDeviceControlTypeX on SpaceDeviceControlType {
  String get routeValue => name;

  String get title {
    switch (this) {
      case SpaceDeviceControlType.climate:
        return 'Climate';
      case SpaceDeviceControlType.fan:
        return 'Fan';
      case SpaceDeviceControlType.ac:
        return 'AC';
      case SpaceDeviceControlType.purifier:
        return 'Purifier';
      case SpaceDeviceControlType.speaker:
        return 'Speaker';
      case SpaceDeviceControlType.ceilingLight:
        return 'Ceiling Light';
      case SpaceDeviceControlType.bulb:
        return 'Bulb';
    }
  }
}

SpaceDeviceControlArgs parseSpaceDeviceControlArgs(dynamic argument) {
  if (argument is SpaceDeviceControlArgs) return argument;
  if (argument is SpaceDeviceControlType) {
    return SpaceDeviceControlArgs(type: argument);
  }
  if (argument is String) {
    return SpaceDeviceControlArgs(type: parseSpaceDeviceControlType(argument));
  }
  return const SpaceDeviceControlArgs(type: SpaceDeviceControlType.climate);
}

SpaceDeviceControlType parseSpaceDeviceControlType(dynamic argument) {
  if (argument is SpaceDeviceControlType) {
    return argument;
  }

  if (argument is String) {
    for (final value in SpaceDeviceControlType.values) {
      if (value.routeValue == argument) return value;
    }
  }

  return SpaceDeviceControlType.climate;
}

SpaceDeviceControlType mapDeviceNameToControlType(String name) {
  final normalized = name.toLowerCase().trim();
  if (normalized.contains('climate')) return SpaceDeviceControlType.climate;
  if (normalized == 'fan') return SpaceDeviceControlType.fan;
  if (normalized == 'ac' || normalized.contains('air conditioner')) {
    return SpaceDeviceControlType.ac;
  }
  if (normalized.contains('purifier')) return SpaceDeviceControlType.purifier;
  if (normalized.contains('speaker')) return SpaceDeviceControlType.speaker;
  if (normalized.contains('ceiling light') || normalized.contains('ceilling')) {
    return SpaceDeviceControlType.ceilingLight;
  }
  if (normalized == 'bulb') return SpaceDeviceControlType.bulb;
  return SpaceDeviceControlType.climate;
}
