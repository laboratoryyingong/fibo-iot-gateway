import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';

/// Rich "My Home" card rendered from a `get_devices` tool result, mirroring
/// design/fibo_claude_agent.pen › "44. Devices Dashboard".
///
/// Devices are grouped by room; each room tile shows its device count and a
/// short, truthful status line derived from device state.
class AssistantDeviceDashboard extends StatelessWidget {
  const AssistantDeviceDashboard({super.key, required this.devices});

  final List<AgentDevice> devices;

  @override
  Widget build(BuildContext context) {
    final rooms = _groupByRoom(devices);
    final offline = devices.where((d) => !d.online).length;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AgentColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AgentColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(offline: offline),
          const SizedBox(height: 12),
          for (var i = 0; i < rooms.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _RoomTile(room: rooms[i])),
                  const SizedBox(width: 8),
                  if (i + 1 < rooms.length)
                    Expanded(child: _RoomTile(room: rooms[i + 1]))
                  else
                    const Spacer(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _SeeAllButton(count: devices.length),
        ],
      ),
    );
  }

  List<_RoomGroup> _groupByRoom(List<AgentDevice> devices) {
    final byRoom = <String, List<AgentDevice>>{};
    for (final d in devices) {
      byRoom.putIfAbsent(d.room ?? 'other', () => []).add(d);
    }
    return byRoom.entries
        .map((e) => _RoomGroup(id: e.key, devices: e.value))
        .toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.offline});

  final int offline;

  @override
  Widget build(BuildContext context) {
    final allOnline = offline == 0;
    return Row(
      children: [
        const Icon(Icons.home_rounded, size: 18, color: AgentColors.logoStrokeB),
        const SizedBox(width: 8),
        const Text(
          'My Home',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AgentColors.ink,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: allOnline ? const Color(0xFF1E3A2C) : const Color(0xFF3D3416),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allOnline
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                allOnline ? 'All online' : '$offline offline',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: allOnline
                      ? const Color(0xFF6EE7A8)
                      : const Color(0xFFFFD17A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final _RoomGroup room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AgentColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AgentColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(room.icon, size: 16, color: AgentColors.inkMuted),
              const Spacer(),
              Text(
                '${room.devices.length} ${room.devices.length == 1 ? "device" : "devices"}',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11.5,
                  color: AgentColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            room.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AgentColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            room.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: AgentColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/spaces/devices'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AgentColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AgentColors.stroke),
        ),
        child: Row(
          children: [
            Text(
              'See all $count devices',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AgentColors.ink,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AgentColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _RoomGroup {
  _RoomGroup({required this.id, required this.devices});

  final String id;
  final List<AgentDevice> devices;

  String get title => id
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  IconData get icon {
    final key = id.toLowerCase();
    if (key.contains('living')) return Icons.weekend_outlined;
    if (key.contains('kitchen')) return Icons.restaurant_outlined;
    if (key.contains('bed')) return Icons.bed_outlined;
    if (key.contains('bath')) return Icons.bathtub_outlined;
    if (key.contains('office') || key.contains('study')) {
      return Icons.chair_alt_outlined;
    }
    if (key.contains('entrance') || key.contains('door') || key.contains('hall')) {
      return Icons.meeting_room_outlined;
    }
    return Icons.grid_view_rounded;
  }

  /// Short, truthful status line derived from the room's device state.
  String get status {
    final parts = <String>[];

    final light = _firstOfType('light');
    if (light != null && light.isOn != null) {
      parts.add(light.isOn! ? 'Light on' : 'Light off');
    }

    final lock = _firstOfType('lock');
    if (lock != null) {
      final s = lock.state['state'] ?? lock.state['locked'];
      if (s == 'locked' || s == true) {
        parts.add('Locked');
      } else if (s == 'unlocked' || s == false) {
        parts.add('Unlocked');
      }
    }

    for (final d in devices) {
      final temp = d.state['temperature'];
      if (temp is num) {
        parts.add('${temp.toStringAsFixed(temp % 1 == 0 ? 0 : 1)}°');
        break;
      }
    }

    if (parts.isEmpty) {
      final offline = devices.where((d) => !d.online).length;
      parts.add(offline == 0 ? 'All online' : '$offline offline');
    }
    return parts.take(2).join(' · ');
  }

  AgentDevice? _firstOfType(String type) {
    for (final d in devices) {
      if (d.type.toLowerCase().contains(type)) return d;
    }
    return null;
  }
}
