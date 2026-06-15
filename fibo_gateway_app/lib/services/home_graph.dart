import 'dart:convert';

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// App-domain structure for a home, loaded from the Parse `listHomeGraph` cloud
/// function. This is the *structure* layer (rooms, device metadata, scenes);
/// live device state is overlaid separately from the IoT shadow, joined on
/// [HomeDevice.shadowName].
class HomeGraph {
  const HomeGraph({
    required this.homeId,
    required this.homeName,
    required this.homeLocation,
    required this.role,
    required this.spaces,
    required this.devices,
    required this.scenes,
    required this.members,
  });

  final String homeId;
  final String homeName;
  final String homeLocation;
  final String role;
  final List<HomeSpace> spaces;
  final List<HomeDevice> devices;
  final List<HomeScene> scenes;
  final List<HomeMemberInfo> members;
}

class HomeScene {
  const HomeScene({
    required this.sceneId,
    required this.name,
    required this.icon,
    required this.enabled,
    required this.actionCount,
  });

  final String sceneId;
  final String name;
  final String icon; // emoji / token
  final bool enabled;
  final int actionCount;
}

class HomeMemberInfo {
  const HomeMemberInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  final String? userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
}

class HomeSpace {
  const HomeSpace({
    required this.spaceId,
    required this.name,
    required this.sortOrder,
  });

  final String spaceId;
  final String name;
  final int sortOrder;
}

class HomeDevice {
  const HomeDevice({
    required this.endpointKey,
    required this.shadowName,
    required this.spaceId,
    required this.profile,
    required this.displayName,
    required this.iconKey,
    required this.sortOrder,
  });

  final String endpointKey; // stable key used by scene actions
  final String shadowName; // join key to the IoT shadow
  final String? spaceId;
  final String profile;
  final String displayName;
  final String? iconKey;
  final int sortOrder;

  /// True when this profile can be driven by a deterministic scene action.
  bool get isSceneControllable => const {
        'color_light',
        'dimmable_light',
        'onoff_actuator',
        'curtain',
        'door_lock',
      }.contains(profile);
}

/// Calls `listHomeGraph` and returns the typed structure for [homeId].
Future<HomeGraph> fetchHomeGraph(String homeId) async {
  final fn = ParseCloudFunction('listHomeGraph');
  final resp = await fn.execute(parameters: {'homeId': homeId});
  if (!resp.success || resp.result is! Map) {
    throw Exception('listHomeGraph failed: ${resp.error?.message}');
  }
  final result = (resp.result as Map).cast<String, dynamic>();
  final home = _asMap(result['home']);
  final membership = _asMap(result['membership']);

  final spaces = <HomeSpace>[];
  for (final raw in _asList(result['spaces'])) {
    final s = _asMap(raw);
    spaces.add(HomeSpace(
      spaceId: s['spaceId']?.toString() ?? '',
      name: s['name']?.toString() ?? '',
      sortOrder: (s['sortOrder'] as num?)?.toInt() ?? 0,
    ));
  }
  spaces.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final devices = <HomeDevice>[];
  for (final raw in _asList(result['devices'])) {
    final d = _asMap(raw);
    final shadow = d['shadowName']?.toString();
    if (shadow == null || shadow.isEmpty) continue;
    devices.add(HomeDevice(
      endpointKey: d['endpointKey']?.toString() ?? '',
      shadowName: shadow,
      spaceId: d['spaceId']?.toString(),
      profile: d['profile']?.toString() ?? 'unknown',
      displayName: d['displayName']?.toString() ?? shadow,
      iconKey: d['iconKey']?.toString(),
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
    ));
  }
  devices.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final scenes = <HomeScene>[];
  for (final raw in _asList(result['scenes'])) {
    final s = _asMap(raw);
    final id = s['sceneId']?.toString();
    if (id == null || id.isEmpty) continue;
    scenes.add(HomeScene(
      sceneId: id,
      name: s['name']?.toString() ?? '',
      icon: s['icon']?.toString() ?? '✨',
      enabled: s['enabled'] != false,
      actionCount: (s['actionCount'] as num?)?.toInt() ?? 0,
    ));
  }

  final members = <HomeMemberInfo>[];
  for (final raw in _asList(result['members'])) {
    final m = _asMap(raw);
    members.add(HomeMemberInfo(
      userId: m['userId']?.toString(),
      name: m['name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      role: m['role']?.toString() ?? 'member',
      status: m['status']?.toString() ?? 'active',
    ));
  }

  return HomeGraph(
    homeId: home['homeId']?.toString() ?? homeId,
    homeName: home['name']?.toString() ?? '',
    homeLocation: home['location']?.toString() ?? '',
    role: membership['role']?.toString() ?? 'member',
    spaces: spaces,
    devices: devices,
    scenes: scenes,
    members: members,
  );
}

/// Runs a scene via the `executeScene` cloud function (server writes each
/// action's desired state to the device shadows). Throws on failure.
Future<void> requestExecuteScene(String homeId, String sceneId) async {
  final fn = ParseCloudFunction('executeScene');
  final resp =
      await fn.execute(parameters: {'homeId': homeId, 'sceneId': sceneId});
  if (!resp.success) {
    throw Exception('executeScene failed: ${resp.error?.message}');
  }
}

/// Persists the editable home + owner profile fields via `updateHomeProfile`.
Future<void> updateHomeProfile({
  required String homeId,
  required String name,
  required String location,
  required String fullName,
  required String phone,
}) async {
  final fn = ParseCloudFunction('updateHomeProfile');
  final resp = await fn.execute(parameters: {
    'homeId': homeId,
    'home': {'name': name, 'location': location},
    'owner': {'fullName': fullName, 'phone': phone},
  });
  if (!resp.success) {
    throw Exception(_cloudError(resp, 'updateHomeProfile'));
  }
}

/// Invites an existing account into the home (`inviteHomeMember`).
Future<void> inviteHomeMember({
  required String homeId,
  required String email,
  required String role,
}) async {
  final fn = ParseCloudFunction('inviteHomeMember');
  final resp = await fn.execute(
    parameters: {'homeId': homeId, 'email': email, 'role': role},
  );
  if (!resp.success) {
    throw Exception(_cloudError(resp, 'inviteHomeMember'));
  }
}

/// Removes a member from the home (`removeHomeMember`).
Future<void> removeHomeMember({
  required String homeId,
  required String userId,
}) async {
  final fn = ParseCloudFunction('removeHomeMember');
  final resp = await fn.execute(
    parameters: {'homeId': homeId, 'userId': userId},
  );
  if (!resp.success) {
    throw Exception(_cloudError(resp, 'removeHomeMember'));
  }
}

/// Extracts a human-readable message from a failed cloud response. Cloud errors
/// are JSON `{code,message,details}`; fall back to the raw message otherwise.
String _cloudError(ParseResponse resp, String fn) {
  final raw = resp.error?.message ?? '';
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'] as String;
    }
  } catch (_) {
    // not JSON
  }
  return raw.isEmpty ? '$fn failed' : raw;
}

Map<String, dynamic> _asMap(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};
List _asList(Object? v) => v is List ? v : const [];
