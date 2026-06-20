import 'package:flutter/foundation.dart';
import 'package:fibo_core/services/aws_iot_session.dart';
import 'package:fibo_core/services/cognito_credentials_provider.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/services/iot_shadow_client.dart';

enum HomeLoadState { loading, ready, error }

/// What kind of control a device card offers.
enum DeviceKind { light, dimmableLight, onoff, lock, curtain, siren, sensor }

/// Derived UI state for a single device, computed from its live shadow plus any
/// optimistic intent still in flight.
class DeviceView {
  const DeviceView({
    required this.kind,
    required this.isOn,
    required this.online,
    required this.pending,
    this.valueLabel,
    this.levelPercent,
  });

  final DeviceKind kind;
  final bool isOn;
  final bool online;
  final bool pending;
  final String? valueLabel;
  final int? levelPercent; // dimmable lights / curtains

  bool get isToggle =>
      kind == DeviceKind.light ||
      kind == DeviceKind.dimmableLight ||
      kind == DeviceKind.onoff ||
      kind == DeviceKind.siren ||
      kind == DeviceKind.curtain;

  bool get isLock => kind == DeviceKind.lock;
  bool get hasSlider =>
      kind == DeviceKind.dimmableLight || kind == DeviceKind.curtain;
}

/// Loads the home structure (Parse) and overlays live device state from the AWS
/// IoT named shadows, and writes control intent back through the same client.
class HomeController extends ChangeNotifier {
  HomeLoadState state = HomeLoadState.loading;
  HomeGraph? graph;
  String? error;

  final _cognito = CognitoCredentialsProvider();
  late final _iot = IotShadowClient(credentials: _cognito);
  bool _listening = false;

  // shadowName -> reported shadow doc (nested state/telemetry/connectivity).
  final Map<String, Map<String, dynamic>> _reported = {};
  // shadowName -> optimistic desired state patch awaiting confirmation.
  final Map<String, Map<String, dynamic>> _pending = {};
  final Map<String, int> _pendingEpoch = {};

  /// Whether the live IoT shadow connection is up (device state is flowing).
  bool get shadowsConnected => _iot.isConnected;

  /// Scenes defined for this home.
  List<HomeScene> get scenes => graph?.scenes ?? const [];

  /// Triggers a scene by id. Throws on failure so callers can surface it.
  Future<void> runScene(String sceneId) async {
    final g = graph;
    if (g == null) throw Exception('Home not loaded');
    await requestExecuteScene(g.homeId, sceneId);
  }

  Future<void> load() async {
    state = HomeLoadState.loading;
    error = null;
    notifyListeners();
    try {
      final session = await configureCognitoFromParse(_cognito);
      graph = await fetchHomeGraph(session.homeId);
      state = HomeLoadState.ready;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      state = HomeLoadState.error;
      notifyListeners();
      return;
    }
    // Live shadow state is best-effort: structure already renders without it.
    _connectShadows();
  }

  Future<void> _connectShadows() async {
    final g = graph;
    if (g == null) return;
    try {
      if (!_listening) {
        _iot.events.listen(_onShadow);
        _listening = true;
      }
      await _iot.connect();
      final names = g.devices.map((d) => d.shadowName).toList();
      for (var i = 0; i < 6 && _reported.length < names.length; i++) {
        _iot.primeAll(names);
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (_) {
      // Leave the structure visible; cards stay in their default state.
    }
  }

  void _onShadow(HubShadowEvent ev) {
    _reported[ev.shadowName] = ev.reported;
    _maybeClearPending(ev.shadowName);
    notifyListeners();
  }

  // --- Control -------------------------------------------------------------

  void toggle(HomeDevice device) {
    final view = viewFor(device);
    if (view.isLock) {
      _writeDesired(device.shadowName, {'locked': !view.isOn});
      return;
    }
    final patch = _powerDesired(device.profile, !view.isOn);
    if (patch == null) return;
    _writeDesired(device.shadowName, patch);
  }

  /// Sets brightness (lights) or open position (curtains) as a 0-100 percent.
  void setPercent(HomeDevice device, int percent) {
    final p = percent.clamp(0, 100);
    switch (device.profile) {
      case 'color_light':
      case 'dimmable_light':
        _writeDesired(device.shadowName, {'level': (p / 100 * 255).round()});
        break;
      case 'curtain':
        _writeDesired(device.shadowName, {'lift_percent': p});
        break;
    }
  }

  Map<String, dynamic>? _powerDesired(String profile, bool on) {
    switch (profile) {
      case 'color_light':
      case 'dimmable_light':
      case 'onoff_actuator':
        return {'power': on ? 1 : 0};
      case 'siren_actuator':
        return {'alarm': on};
      case 'curtain':
        return {'lift_percent': on ? 100 : 0};
      default:
        return null;
    }
  }

  void _writeDesired(String shadowName, Map<String, dynamic> patch) {
    _pending[shadowName] = {...?_pending[shadowName], ...patch};
    final epoch = (_pendingEpoch[shadowName] ?? 0) + 1;
    _pendingEpoch[shadowName] = epoch;
    _iot.setDesired(shadowName, {'state': patch});
    notifyListeners();
    // Drop a stale intent if the device never reports back.
    Future.delayed(const Duration(seconds: 8), () {
      if (_pendingEpoch[shadowName] == epoch &&
          _pending.remove(shadowName) != null) {
        _pendingEpoch.remove(shadowName);
        notifyListeners();
      }
    });
  }

  void _maybeClearPending(String shadowName) {
    final pending = _pending[shadowName];
    if (pending == null) return;
    final reported = _reported[shadowName];
    final raw = reported?['state'];
    final st = raw is Map ? raw.cast<String, dynamic>() : const {};
    if (pending.entries.every((e) => st[e.key] == e.value)) {
      _pending.remove(shadowName);
      _pendingEpoch.remove(shadowName);
    }
  }

  // --- Derived state -------------------------------------------------------

  DeviceView viewFor(HomeDevice device) {
    final reported = _reported[device.shadowName] ?? const {};
    final reportedState = reported['state'] is Map
        ? (reported['state'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final pending = _pending[device.shadowName];
    final st = pending == null ? reportedState : {...reportedState, ...pending};
    final tel = reported['telemetry'] is Map
        ? (reported['telemetry'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final conn = reported['connectivity'] is Map
        ? (reported['connectivity'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final online = conn['online'] as bool? ?? true;
    final isPending = pending != null;

    DeviceKind kind = DeviceKind.sensor;
    var isOn = false;
    String? valueLabel;
    int? levelPercent;

    switch (device.profile) {
      case 'color_light':
        kind = DeviceKind.dimmableLight;
        isOn = st['power'] == 1;
        final level = st['level'];
        if (level is num) {
          levelPercent = (level / 254 * 100).round().clamp(0, 100);
          valueLabel = isOn ? '$levelPercent%' : 'Off';
        }
        break;
      case 'dimmable_light':
        kind = DeviceKind.dimmableLight;
        isOn = st['power'] == 1;
        final level = st['level'];
        if (level is num) {
          levelPercent = (level / 254 * 100).round().clamp(0, 100);
          valueLabel = isOn ? '$levelPercent%' : 'Off';
        }
        break;
      case 'onoff_actuator':
        kind = DeviceKind.onoff;
        isOn = st['power'] == 1;
        valueLabel = isOn ? 'On' : 'Off';
        break;
      case 'curtain':
        kind = DeviceKind.curtain;
        final lift = st['lift_percent'];
        if (lift is num) {
          levelPercent = lift.round().clamp(0, 100);
          isOn = lift > 0;
          valueLabel = '$levelPercent% open';
        }
        break;
      case 'door_lock':
        kind = DeviceKind.lock;
        isOn = st['locked'] == true;
        valueLabel = isOn ? 'Locked' : 'Unlocked';
        break;
      case 'siren_actuator':
        kind = DeviceKind.siren;
        isOn = st['alarm'] == true;
        valueLabel = isOn ? 'Sounding' : 'Silent';
        break;
      case 'smoke_alarm':
        isOn = tel['alarm_active'] == true;
        valueLabel = isOn ? 'Smoke!' : 'Clear';
        break;
      case 'ias_sensor':
        final zs = tel['zone_status'];
        isOn = zs is num && zs != 0;
        valueLabel = isOn ? 'Motion' : 'Clear';
        break;
      case 'multi_sensor':
        final t = tel['temperature_centi_c'];
        if (t is num) valueLabel = '${(t / 100).toStringAsFixed(1)}°';
        break;
      case 'mmwave_sensor':
        valueLabel = 'Presence';
        break;
    }

    return DeviceView(
      kind: kind,
      isOn: isOn,
      online: online,
      pending: isPending,
      valueLabel: valueLabel,
      levelPercent: levelPercent,
    );
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

  @override
  void dispose() {
    _iot.disconnect();
    super.dispose();
  }
}

class RoomGroup {
  const RoomGroup({required this.name, required this.devices});

  final String name;
  final List<HomeDevice> devices;
}
