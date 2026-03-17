import 'dart:convert';

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'user_role_resolver.dart';

enum GatewayConnectionState { online, offline, updating, error }

class GatewayProfile {
  const GatewayProfile({
    required this.id,
    required this.name,
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.connectionState,
    this.location,
    this.activeDeviceCount = 0,
    this.lastSeenLabel,
  });

  final String id;
  final String name;
  final String model;
  final String serialNumber;
  final String firmwareVersion;
  final GatewayConnectionState connectionState;
  final String? location;
  final int activeDeviceCount;
  final String? lastSeenLabel;

  bool get isOnline => connectionState == GatewayConnectionState.online;

  String get statusLabel {
    switch (connectionState) {
      case GatewayConnectionState.online:
        return 'Online';
      case GatewayConnectionState.offline:
        return 'Offline';
      case GatewayConnectionState.updating:
        return 'Updating';
      case GatewayConnectionState.error:
        return 'Error';
    }
  }

  GatewayProfile copyWith({
    String? id,
    String? name,
    String? model,
    String? serialNumber,
    String? firmwareVersion,
    GatewayConnectionState? connectionState,
    String? location,
    int? activeDeviceCount,
    String? lastSeenLabel,
  }) {
    return GatewayProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      connectionState: connectionState ?? this.connectionState,
      location: location ?? this.location,
      activeDeviceCount: activeDeviceCount ?? this.activeDeviceCount,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'connectionState': connectionState.name,
      'location': location,
      'activeDeviceCount': activeDeviceCount,
      'lastSeenLabel': lastSeenLabel,
    };
  }

  factory GatewayProfile.fromJson(Map<String, dynamic> json) {
    final stateName = json['connectionState'] as String?;
    final state = GatewayConnectionState.values.where(
      (value) => value.name == stateName,
    );

    return GatewayProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'FIBO Gateway',
      model: json['model'] as String? ?? 'FIBO Gateway',
      serialNumber: json['serialNumber'] as String? ?? 'UNKNOWN',
      firmwareVersion: json['firmwareVersion'] as String? ?? 'v2.4.1',
      connectionState: state.isEmpty
          ? GatewayConnectionState.online
          : state.first,
      location: json['location'] as String?,
      activeDeviceCount: (json['activeDeviceCount'] as num?)?.toInt() ?? 0,
      lastSeenLabel: json['lastSeenLabel'] as String?,
    );
  }
}

class GatewayLinkingService {
  static const onboardingRoute = '/gateway/onboarding';
  static const listRoute = '/gateway/list';
  static const detailRoute = '/gateway/detail';
  static const statusRoute = '/gateway/status';

  static const _linkedGatewaysJsonKey = 'linkedGatewaysJson';
  static const _selectedGatewayIdKey = 'selectedGatewayId';

  static const List<GatewayProfile> _mockGatewayCatalog = [
    GatewayProfile(
      id: 'gw-a1b2c3',
      name: 'FIBO Gateway Pro',
      model: 'FIBO Gateway Pro',
      serialNumber: 'A1B2C3',
      firmwareVersion: 'v2.4.1',
      connectionState: GatewayConnectionState.online,
      activeDeviceCount: 24,
      location: 'Home / Living Room',
      lastSeenLabel: 'Just now',
    ),
    GatewayProfile(
      id: 'gw-d4e5f6',
      name: 'FIBO Gateway Mini',
      model: 'FIBO Gateway Mini',
      serialNumber: 'D4E5F6',
      firmwareVersion: 'v2.3.8',
      connectionState: GatewayConnectionState.offline,
      activeDeviceCount: 14,
      location: 'Home / Hallway',
      lastSeenLabel: '2 min ago',
    ),
    GatewayProfile(
      id: 'gw-g7h8i9',
      name: 'FIBO Gateway 2nd Gen',
      model: 'FIBO Gateway 2nd Gen',
      serialNumber: 'G7H8I9',
      firmwareVersion: 'v2.5.0',
      connectionState: GatewayConnectionState.updating,
      activeDeviceCount: 31,
      location: 'Villa / Control Room',
      lastSeenLabel: 'Updating',
    ),
    GatewayProfile(
      id: 'gw-j1k2l3',
      name: 'FIBO Gateway Lite',
      model: 'FIBO Gateway Lite',
      serialNumber: 'J1K2L3',
      firmwareVersion: 'v2.1.6',
      connectionState: GatewayConnectionState.offline,
      activeDeviceCount: 8,
      location: 'Studio',
      lastSeenLabel: '45 min ago',
    ),
  ];

  static Future<String> resolvePostAuthRoute(ParseUser user) async {
    final selectedGateway = await getSelectedGateway(user);
    if (selectedGateway != null) return resolveHomeRoute(user);
    return onboardingRoute;
  }

  static Future<bool> hasLinkedGateway([ParseUser? user]) async {
    return await getSelectedGateway(user) != null;
  }

  static Future<List<GatewayProfile>> getLinkedGateways([
    ParseUser? user,
  ]) async {
    final activeUser = user ?? await _currentUser();
    if (activeUser == null) return const [];

    final rawJson = activeUser.get<String>(_linkedGatewaysJsonKey);
    if (rawJson == null || rawJson.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => GatewayProfile.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((gateway) => gateway.id.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return const [];
    }
  }

  static Future<GatewayProfile?> getSelectedGateway([ParseUser? user]) async {
    final activeUser = user ?? await _currentUser();
    if (activeUser == null) return null;

    final gateways = await getLinkedGateways(activeUser);
    if (gateways.isEmpty) return null;

    final selectedId = activeUser.get<String>(_selectedGatewayIdKey);
    if (selectedId == null || selectedId.trim().isEmpty) {
      return gateways.first;
    }

    for (final gateway in gateways) {
      if (gateway.id == selectedId) return gateway;
    }
    return gateways.first;
  }

  static GatewayProfile suggestedGateway() {
    return _mockGatewayCatalog.first;
  }

  static List<GatewayProfile> mockDiscoveryCandidates() {
    return List.unmodifiable(_mockGatewayCatalog.take(3));
  }

  static List<GatewayProfile> mockLinkedGateways({
    required GatewayProfile primaryGateway,
  }) {
    final deduped = <GatewayProfile>[primaryGateway];
    for (final candidate in _mockGatewayCatalog) {
      final exists = deduped.any(
        (gateway) =>
            gateway.id == candidate.id ||
            gateway.serialNumber == candidate.serialNumber,
      );
      if (!exists) deduped.add(candidate);
    }
    return deduped;
  }

  static GatewayProfile gatewayFromCode(String rawCode) {
    final normalized = rawCode
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase()
        .trim();
    final safeCode = normalized.isEmpty ? 'A1B2C3' : normalized;
    for (final gateway in _mockGatewayCatalog) {
      if (gateway.serialNumber == safeCode) return gateway;
    }

    return GatewayProfile(
      id: 'gw-${safeCode.toLowerCase()}',
      name: 'FIBO Gateway Pro',
      model: 'FIBO Gateway Pro',
      serialNumber: safeCode,
      firmwareVersion: 'v2.4.1',
      connectionState: GatewayConnectionState.online,
      activeDeviceCount: 0,
      location: 'Home / Living Room',
      lastSeenLabel: 'Just now',
    );
  }

  static String uptimeLabelFor(GatewayProfile gateway) {
    switch (gateway.id) {
      case 'gw-a1b2c3':
        return '14 days 6 hours';
      case 'gw-d4e5f6':
        return '7 days 9 hours';
      case 'gw-g7h8i9':
        return 'Applying update';
      case 'gw-j1k2l3':
        return '2 days 3 hours';
      default:
        return gateway.isOnline ? '3 days 4 hours' : 'Unavailable';
    }
  }

  static String linkQualityLabelFor(GatewayProfile gateway) {
    switch (gateway.connectionState) {
      case GatewayConnectionState.online:
        return gateway.id == 'gw-a1b2c3' ? '98%' : '91%';
      case GatewayConnectionState.offline:
        return '--';
      case GatewayConnectionState.updating:
        return '67%';
      case GatewayConnectionState.error:
        return 'ERR';
    }
  }

  static String channelLabelFor(GatewayProfile gateway) {
    switch (gateway.id) {
      case 'gw-d4e5f6':
        return '20';
      case 'gw-g7h8i9':
        return '25';
      case 'gw-j1k2l3':
        return '11';
      default:
        return '15';
    }
  }

  static String macAddressFor(GatewayProfile gateway) {
    switch (gateway.id) {
      case 'gw-d4e5f6':
        return '84:A2:3B:9C:D4:E5';
      case 'gw-g7h8i9':
        return '84:A2:3B:9C:67:89';
      case 'gw-j1k2l3':
        return '84:A2:3B:9C:11:23';
      default:
        return '84:A2:3B:9C:A1:B2';
    }
  }

  static bool permitJoinEnabledFor(GatewayProfile gateway) {
    return gateway.connectionState == GatewayConnectionState.online &&
        gateway.id == 'gw-a1b2c3';
  }

  static String powerModeFor(GatewayProfile gateway) {
    return gateway.id == 'gw-j1k2l3' ? 'Balanced' : 'High';
  }

  static String ledIndicatorFor(GatewayProfile gateway) {
    return gateway.connectionState == GatewayConnectionState.offline
        ? 'Blink'
        : 'On';
  }

  static String firmwareStatusFor(GatewayProfile gateway) {
    return gateway.connectionState == GatewayConnectionState.updating
        ? 'Installing'
        : 'Up to date';
  }

  static Future<bool> bindGateway({
    required ParseUser user,
    required GatewayProfile gateway,
    required String gatewayName,
    String? location,
  }) async {
    final gateways = await getLinkedGateways(user);
    final trimmedName = gatewayName.trim();
    final trimmedLocation = location?.trim();
    final boundGateway = gateway.copyWith(
      name: trimmedName.isEmpty ? gateway.name : trimmedName,
      location: trimmedLocation == null || trimmedLocation.isEmpty
          ? gateway.location
          : trimmedLocation,
      connectionState: GatewayConnectionState.online,
      lastSeenLabel: 'Just now',
    );

    final nextGateways = gateways.isEmpty
        ? mockLinkedGateways(
            primaryGateway: boundGateway,
          ).toList(growable: true)
        : gateways.toList(growable: true);

    final index = nextGateways.indexWhere((item) => item.id == boundGateway.id);
    if (index >= 0) {
      nextGateways[index] = boundGateway;
    } else {
      nextGateways.insert(0, boundGateway);
    }

    return _persistGateways(
      user: user,
      gateways: nextGateways,
      selectedGatewayId: boundGateway.id,
    );
  }

  static Future<bool> selectGateway({
    required ParseUser user,
    required String gatewayId,
  }) async {
    final gateways = await getLinkedGateways(user);
    final exists = gateways.any((gateway) => gateway.id == gatewayId);
    if (!exists) return false;
    return _persistGateways(
      user: user,
      gateways: gateways,
      selectedGatewayId: gatewayId,
    );
  }

  static Future<bool> unbindGateway({
    required ParseUser user,
    required String gatewayId,
  }) async {
    final gateways = await getLinkedGateways(user);
    gateways.removeWhere((gateway) => gateway.id == gatewayId);

    if (gateways.isEmpty) {
      await user.unset(_linkedGatewaysJsonKey);
      await user.unset(_selectedGatewayIdKey);
      final response = await user.save();
      return response.success;
    }

    return _persistGateways(
      user: user,
      gateways: gateways,
      selectedGatewayId: gateways.first.id,
    );
  }

  static Future<ParseUser?> _currentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  static Future<bool> _persistGateways({
    required ParseUser user,
    required List<GatewayProfile> gateways,
    required String selectedGatewayId,
  }) async {
    user.set<String>(
      _linkedGatewaysJsonKey,
      jsonEncode(gateways.map((gateway) => gateway.toJson()).toList()),
    );
    user.set<String>(_selectedGatewayIdKey, selectedGatewayId);
    final response = await user.save();
    return response.success;
  }
}
