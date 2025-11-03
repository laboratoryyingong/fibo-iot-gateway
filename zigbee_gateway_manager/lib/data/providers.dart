import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/mqtt_service.dart';
import '../models/device.dart';
import '../models/gateway_config.dart';

enum GatewayStatus { disconnected, connecting, connected, reconnecting }

const _kBoxApp = 'app';
const _kKeyConfig = 'config';
const _kKeyDevices = 'devices';

final hiveBoxProvider = Provider<Box>((ref) => throw UnimplementedError());

class GatewayConfigNotifier extends Notifier<GatewayConfig?> {
  @override
  GatewayConfig? build() {
    final box = ref.read(hiveBoxProvider);
    final raw = box.get(_kKeyConfig);
    if (raw is String) {
      return GatewayConfig.fromJson(jsonDecode(raw));
    }
    return null;
  }

  void setConfig(GatewayConfig c) {
    state = c;
    final box = ref.read(hiveBoxProvider);
    box.put(_kKeyConfig, jsonEncode(c.toJson()));
  }

  void clear() {
    state = null;
    final box = ref.read(hiveBoxProvider);
    box.delete(_kKeyConfig);
  }
}

final gatewayConfigProvider =
    NotifierProvider<GatewayConfigNotifier, GatewayConfig?>(
      GatewayConfigNotifier.new,
    );

class DeviceStore extends Notifier<Map<String, Device>> {
  @override
  Map<String, Device> build() {
    final box = ref.read(hiveBoxProvider);
    final raw = box.get(_kKeyDevices);
    if (raw is String) {
      final list = (jsonDecode(raw) as List)
          .cast<dynamic>()
          .map((e) => Device.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final map = <String, Device>{};
      for (final d in list) {
        map[d.ieeeAddr] = d;
      }
      return map;
    }
    return {};
  }

  void _persist() {
    final box = ref.read(hiveBoxProvider);
    final list = state.values.map((e) => e.toJson()).toList();
    box.put(_kKeyDevices, jsonEncode(list));
  }

  void setDevices(List<Device> list) {
    final map = <String, Device>{};
    for (final d in list) {
      map[d.ieeeAddr] = d;
    }
    state = map;
    _persist();
  }

  void upsertState(String ieee, Map<String, dynamic> inc) {
    final old = state[ieee];
    if (old != null) {
      final next = old.copyWith(state: {...old.state, ...inc});
      state = {...state, ieee: next};
    } else {
      state = {
        ...state,
        ieee: Device(
          ieeeAddr: ieee,
          type: 'unknown',
          friendlyName: ieee,
          online: true,
          state: inc,
        ),
      };
    }
    _persist();
  }
}

final deviceStoreProvider = NotifierProvider<DeviceStore, Map<String, Device>>(
  DeviceStore.new,
);

final gatewayStatusProvider = StateProvider<GatewayStatus>(
  (ref) => GatewayStatus.disconnected,
);

final mqttServiceProvider = Provider<MqttService?>((ref) {
  final conf = ref.watch(gatewayConfigProvider);
  if (conf == null) return null;
  return MqttService(
    clientId: 'ios-${DateTime.now().millisecondsSinceEpoch}',
    broker: conf.host,
    port: conf.port,
    useWebSocket: conf.useWebSocket,
    secure: conf.secure,
    // wsPath: conf.wsPath,
    username: conf.username,
    password: conf.password,
  );
});

class GatewayController extends AsyncNotifier<void> {
  StreamSubscription? _sub;

  @override
  Future<void> build() async {
    final conf = ref.watch(gatewayConfigProvider);
    final status = ref.read(gatewayStatusProvider.notifier);

    ref.onDispose(() {
      _sub?.cancel();
      final svc = ref.read(mqttServiceProvider);
      svc?.dispose();
      status.state = GatewayStatus.disconnected;
    });

    if (conf == null) return;

    final svc = ref.read(mqttServiceProvider)!;
    status.state = GatewayStatus.connecting;
    await svc.connect();
    status.state = GatewayStatus.connected;

    svc.subscribe('gw/${conf.gwId}/devices');
    svc.subscribe('dev/+/state');

    _sub = svc.updates.listen((m) {
      final event = m['event'];
      if (event == 'reconnecting') {
        status.state = GatewayStatus.reconnecting;
      } else if (event == 'reconnected' || event == 'connected') {
        status.state = GatewayStatus.connected;
      } else if (event == 'disconnected') {
        status.state = GatewayStatus.disconnected;
      } else if (event == 'message') {
        final topic = m['topic'] as String;
        final payload = m['payload'] as String;
        try {
          final j = jsonDecode(payload);
          if (topic == 'gw/${conf.gwId}/devices' && j is List) {
            final list = j
                .map<Device>(
                  (e) => Device.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
            ref.read(deviceStoreProvider.notifier).setDevices(list);
          } else if (topic.startsWith('dev/') && topic.endsWith('/state')) {
            final ieee = topic.split('/')[1];
            ref
                .read(deviceStoreProvider.notifier)
                .upsertState(ieee, Map<String, dynamic>.from(j));
          }
        } catch (_) {}
      }
    });
  }

  void setOnOff(String ieee, bool on) {
    final svc = ref.read(mqttServiceProvider);
    if (svc == null) return;
    svc.publishJson('dev/$ieee/set', {"on": on});
  }

  void setBrightness(String ieee, int v) {
    final svc = ref.read(mqttServiceProvider);
    if (svc == null) return;
    svc.publishJson('dev/$ieee/set', {"brightness": v.clamp(1, 254)});
  }

  void setColorTemp(String ieee, int mired) {
    final svc = ref.read(mqttServiceProvider);
    if (svc == null) return;
    svc.publishJson('dev/$ieee/set', {"color_temp": mired.clamp(150, 500)});
  }

  void setPermitJoin(bool on, {int timeout = 120}) {
    final conf = ref.read(gatewayConfigProvider);
    final svc = ref.read(mqttServiceProvider);
    if (conf == null || svc == null) return;
    svc.publishJson('gw/${conf.gwId}/permit_join/set', {
      "on": on,
      "timeout": timeout,
    });
  }
}

final gatewayControllerProvider =
    AsyncNotifierProvider<GatewayController, void>(GatewayController.new);
