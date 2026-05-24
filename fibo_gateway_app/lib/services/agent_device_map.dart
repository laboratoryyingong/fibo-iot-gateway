// v0 hand-mapped agent device IDs -> (room, device name) pairs in
// SpaceMockStore. Replace with a join via ShadowEndpointBinding.shadowName
// once agent ids (`light.*`) and shadow ids (`dev_00158d…`) are unified.
//
// V0 covers light devices only; AC / curtain / lock / TV intentionally absent.
// `AgentDeviceSync.applyToolResult` is a silent no-op for unmapped ids so the
// chat UI never blocks on missing mappings.

import '../screens/space_models.dart';
import 'agent_events.dart';

class _AgentDeviceMapping {
  const _AgentDeviceMapping({required this.roomName, required this.deviceName});
  final String roomName;
  final String deviceName;
}

const Map<String, _AgentDeviceMapping> _kAgentDeviceMap = {
  'light.living_room': _AgentDeviceMapping(
    roomName: 'Living Room',
    deviceName: 'Ceiling Light',
  ),
  'light.bedroom': _AgentDeviceMapping(
    roomName: 'Bedroom',
    deviceName: 'Bulb',
  ),
  'light.kitchen': _AgentDeviceMapping(
    roomName: 'Kitchen',
    deviceName: 'Ceiling Light',
  ),
  'light.office': _AgentDeviceMapping(
    roomName: 'Office',
    deviceName: 'Ceiling Light',
  ),
};

class AgentDeviceSync {
  const AgentDeviceSync._();

  /// Reflect a successful `control_device` tool result back into
  /// [SpaceMockStore]. No-op for errors, non-light tools, unmapped device ids,
  /// or devices not present in the local store.
  static void applyToolResult(ToolResultEvent ev) {
    if (ev.isError) return;
    if (ev.name != 'control_device') return; // scenes not synced in v0

    final agentId = ev.input['device_id'] as String?;
    if (agentId == null) return;

    final current = _mapOf(ev.output['current']);
    if (current.isEmpty) return;

    final store = SpaceMockStore.instance;
    final hit = _resolveDevice(store, agentId);
    if (hit == null) return;

    final power = current['power'];
    if (power is String) {
      store.toggleDevicePower(
        roomId: hit.room.id,
        deviceId: hit.device.id,
        value: power == 'on',
      );
    }

    final brightness = current['brightness'];
    if (brightness is num) {
      store.setDeviceLevel(
        roomId: hit.room.id,
        deviceId: hit.device.id,
        value: (brightness.toDouble() / 100.0).clamp(0.0, 1.0),
      );
    }
  }

  static ({SpaceRoom room, SpaceDeviceState device})? _resolveDevice(
    SpaceMockStore store,
    String agentId,
  ) {
    final mapping = _kAgentDeviceMap[agentId];
    if (mapping == null) {
      return store.findFirstDeviceByName(_humanizeAgentId(agentId));
    }
    for (final room in store.rooms) {
      if (room.name != mapping.roomName) continue;
      for (final device in room.devices) {
        if (device.name == mapping.deviceName) {
          return (room: room, device: device);
        }
      }
    }
    return null;
  }

  // Best-effort fallback: "light.living_room" -> "Living Room". Used only when
  // an id is not in _kAgentDeviceMap. Not perfect; the curated map wins.
  static String _humanizeAgentId(String agentId) {
    final lastDot = agentId.lastIndexOf('.');
    final tail = lastDot == -1 ? agentId : agentId.substring(lastDot + 1);
    return tail
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

Map<String, dynamic> _mapOf(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}
