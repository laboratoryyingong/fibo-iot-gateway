import 'package:flutter/foundation.dart';
import 'package:fibo_core/services/aws_iot_session.dart';
import 'package:fibo_core/services/cognito_credentials_provider.dart';
import 'package:fibo_core/services/home_graph.dart';

enum HomeLoadState { loading, ready, error }

/// Loads the home structure for the control hub: resolves the signed-in user's
/// home scope via the Parse `getAwsIotSession` cloud function, then fetches the
/// typed [HomeGraph] (spaces, devices, scenes). Live device state is layered in
/// a later phase.
class HomeController extends ChangeNotifier {
  HomeLoadState state = HomeLoadState.loading;
  HomeGraph? graph;
  String? error;

  Future<void> load() async {
    state = HomeLoadState.loading;
    error = null;
    notifyListeners();
    try {
      final session = await configureCognitoFromParse(
        CognitoCredentialsProvider(),
      );
      graph = await fetchHomeGraph(session.homeId);
      state = HomeLoadState.ready;
    } catch (e) {
      error = e.toString();
      state = HomeLoadState.error;
    }
    notifyListeners();
  }

  /// Devices grouped by their space, ordered as the graph orders spaces.
  /// Devices with no (or unknown) space are collected under a trailing group.
  List<RoomGroup> get rooms {
    final g = graph;
    if (g == null) return const [];
    final bySpace = <String, List<HomeDevice>>{};
    for (final d in g.devices) {
      bySpace.putIfAbsent(d.spaceId ?? '', () => []).add(d);
    }
    final groups = <RoomGroup>[];
    for (final s in g.spaces) {
      final devices = bySpace[s.spaceId] ?? const [];
      if (devices.isEmpty) continue;
      groups.add(RoomGroup(name: s.name, devices: devices));
    }
    final knownIds = g.spaces.map((s) => s.spaceId).toSet();
    final orphans = [
      for (final entry in bySpace.entries)
        if (!knownIds.contains(entry.key)) ...entry.value,
    ];
    if (orphans.isNotEmpty) {
      groups.add(RoomGroup(name: 'Other', devices: orphans));
    }
    return groups;
  }
}

class RoomGroup {
  const RoomGroup({required this.name, required this.devices});

  final String name;
  final List<HomeDevice> devices;
}
