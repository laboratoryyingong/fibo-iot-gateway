class Device {
  final String ieeeAddr;
  final String type;
  final String friendlyName;
  final bool online;
  final Map<String, dynamic> state;
  final List<String> supports;

  Device({
    required this.ieeeAddr,
    required this.type,
    required this.friendlyName,
    required this.online,
    required this.state,
    this.supports = const [],
  });

  Device copyWith({
    String? friendlyName,
    bool? online,
    Map<String, dynamic>? state,
    List<String>? supports,
  }) {
    return Device(
      ieeeAddr: ieeeAddr,
      type: type,
      friendlyName: friendlyName ?? this.friendlyName,
      online: online ?? this.online,
      state: state ?? this.state,
      supports: supports ?? this.supports,
    );
  }

  factory Device.fromJson(Map<String, dynamic> j) {
    return Device(
      ieeeAddr: j['ieeeAddr'] as String,
      type: (j['type'] ?? 'unknown') as String,
      friendlyName: (j['friendlyName'] ?? j['ieeeAddr']) as String,
      online: (j['online'] ?? true) as bool,
      state: Map<String, dynamic>.from(j['state'] ?? {}),
      supports:
          (j['supports'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'ieeeAddr': ieeeAddr,
    'type': type,
    'friendlyName': friendlyName,
    'online': online,
    'state': state,
    'supports': supports,
  };
}
