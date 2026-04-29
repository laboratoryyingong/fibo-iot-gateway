import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShadowFixtureSnapshot {
  const ShadowFixtureSnapshot({
    required this.thingName,
    required this.endpoints,
  });

  final String thingName;
  final List<ShadowEndpointBinding> endpoints;
}

class ShadowEndpointBinding {
  const ShadowEndpointBinding({
    required this.thingName,
    required this.shadowName,
    required this.profile,
    required this.identity,
    required this.connectivity,
    required this.reportedState,
    required this.desiredState,
    required this.capabilities,
    this.lastCommand,
  });

  final String thingName;
  final String shadowName;
  final String profile;
  final Map<String, dynamic> identity;
  final Map<String, dynamic> connectivity;
  final Map<String, dynamic> reportedState;
  final Map<String, dynamic> desiredState;
  final Map<String, dynamic> capabilities;
  final ShadowCommandResult? lastCommand;

  String get ieee => identity['ieee'] as String? ?? '';
  int get endpoint => _shadowIntValue(identity['ep']) ?? 0;
  String? get model => identity['model'] as String?;
  bool get online => connectivity['online'] as bool? ?? false;
  bool get isOn => (_shadowIntValue(reportedState['power']) ?? 0) == 1;
  int? get level => _shadowIntValue(reportedState['level']);
  bool get supportsLevel =>
      capabilities['level'] == true || reportedState['level'] != null;

  double? get levelFraction {
    final rawLevel = level;
    if (rawLevel == null) return null;
    return (rawLevel.clamp(0, 255)) / 255;
  }

  bool get hasPendingWrite => desiredState.isNotEmpty;

  ShadowEndpointBinding copyWith({
    Map<String, dynamic>? identity,
    Map<String, dynamic>? connectivity,
    Map<String, dynamic>? reportedState,
    Map<String, dynamic>? desiredState,
    Map<String, dynamic>? capabilities,
    ShadowCommandResult? lastCommand,
  }) {
    return ShadowEndpointBinding(
      thingName: thingName,
      shadowName: shadowName,
      profile: profile,
      identity: identity ?? this.identity,
      connectivity: connectivity ?? this.connectivity,
      reportedState: reportedState ?? this.reportedState,
      desiredState: desiredState ?? this.desiredState,
      capabilities: capabilities ?? this.capabilities,
      lastCommand: lastCommand ?? this.lastCommand,
    );
  }
}

class ShadowCommandResult {
  const ShadowCommandResult({
    required this.id,
    required this.op,
    required this.status,
    this.completedAt,
    this.error,
  });

  final String id;
  final String op;
  final String status;
  final String? completedAt;
  final Map<String, dynamic>? error;
}

class MockShadowRepository {
  const MockShadowRepository();

  static const fixtureAssetPath =
      'assets/mock/aws_iot_named_shadow_fixtures.json';
  static const supportedProfiles = {'onoff_actuator', 'dimmable_light'};

  Future<ShadowFixtureSnapshot> loadStageOneSnapshot() async {
    final rawJson = await rootBundle.loadString(fixtureAssetPath);
    return parseSnapshot(rawJson);
  }

  @visibleForTesting
  static ShadowFixtureSnapshot parseSnapshot(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Shadow fixture root must be a JSON object.');
    }

    final thingName = decoded['thing_name'] as String? ?? 'fibo-hub-mock';
    final shadows = decoded['named_shadows'];
    if (shadows is! List) {
      return ShadowFixtureSnapshot(thingName: thingName, endpoints: const []);
    }

    final endpoints = <ShadowEndpointBinding>[];
    for (final item in shadows) {
      final shadow = _mapOf(item);
      if (shadow == null) continue;
      if (shadow['kind'] != 'endpoint') continue;

      final profile = shadow['profile'] as String? ?? '';
      if (!supportedProfiles.contains(profile)) continue;

      final document = _mapOf(shadow['document']);
      final state = _mapOf(document?['state']);
      final reported = _mapOf(state?['reported']) ?? const <String, dynamic>{};
      final identity =
          _mapOf(reported['identity']) ?? const <String, dynamic>{};
      final connectivity =
          _mapOf(reported['connectivity']) ?? const <String, dynamic>{};
      final reportedState =
          _mapOf(reported['state']) ?? const <String, dynamic>{};
      final desired = _mapOf(state?['desired']);
      final desiredState =
          _mapOf(desired?['state']) ?? const <String, dynamic>{};
      final capabilities =
          _mapOf(reported['capabilities']) ?? const <String, dynamic>{};
      final lastCommand = _parseLastCommand(reported['last_command']);

      endpoints.add(
        ShadowEndpointBinding(
          thingName: thingName,
          shadowName: shadow['shadow_name'] as String? ?? '',
          profile: profile,
          identity: identity,
          connectivity: connectivity,
          reportedState: reportedState,
          desiredState: desiredState,
          capabilities: capabilities,
          lastCommand: lastCommand,
        ),
      );
    }

    return ShadowFixtureSnapshot(thingName: thingName, endpoints: endpoints);
  }

  static ShadowCommandResult? _parseLastCommand(Object? value) {
    final data = _mapOf(value);
    if (data == null) return null;

    return ShadowCommandResult(
      id: data['id'] as String? ?? '',
      op: data['op'] as String? ?? '',
      status: data['status'] as String? ?? '',
      completedAt: data['completed_at'] as String?,
      error: _mapOf(data['error']),
    );
  }

  static Map<String, dynamic>? _mapOf(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }
}

int? _shadowIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
