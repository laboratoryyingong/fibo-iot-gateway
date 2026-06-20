import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's pinned standby shortcuts: device keys (shadow names) and
/// scene ids, each capped at [max]. Seeded once from sensible defaults on first
/// run, then fully user-managed (add via "+", remove via long-press).
class ShortcutsController extends ChangeNotifier {
  static const _kDevices = 'standby_device_keys';
  static const _kScenes = 'standby_scene_ids';
  static const _kSeeded = 'standby_seeded';
  static const max = 4;

  List<String> deviceKeys = [];
  List<String> sceneIds = [];
  bool loaded = false;
  bool _seeded = false;

  bool get needsSeed => loaded && !_seeded;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    deviceKeys = p.getStringList(_kDevices) ?? [];
    sceneIds = p.getStringList(_kScenes) ?? [];
    _seeded = p.getBool(_kSeeded) ?? false;
    loaded = true;
    notifyListeners();
  }

  /// One-time seed of defaults on first run (no-op afterwards).
  void seedIfNeeded({
    required List<String> devices,
    required List<String> scenes,
  }) {
    if (!needsSeed) return;
    _seeded = true;
    deviceKeys = devices.take(max).toList();
    sceneIds = scenes.take(max).toList();
    _persist();
  }

  void addDevice(String key) {
    if (deviceKeys.length >= max || deviceKeys.contains(key)) return;
    deviceKeys = [...deviceKeys, key];
    _persist();
  }

  void removeDevice(String key) {
    deviceKeys = deviceKeys.where((k) => k != key).toList();
    _persist();
  }

  void addScene(String id) {
    if (sceneIds.length >= max || sceneIds.contains(id)) return;
    sceneIds = [...sceneIds, id];
    _persist();
  }

  void removeScene(String id) {
    sceneIds = sceneIds.where((s) => s != id).toList();
    _persist();
  }

  Future<void> _persist() async {
    _seeded = true;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kDevices, deviceKeys);
    await p.setStringList(_kScenes, sceneIds);
    await p.setBool(_kSeeded, true);
  }
}
