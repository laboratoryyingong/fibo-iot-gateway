import 'package:flutter/material.dart';

import 'package:fibo_core/services/device_api_models.dart';
import 'package:fibo_core/theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Smoke alarm card, mirroring
/// design/fibo_claude_agent.pen › "50. Smoke Alarm". Shows an alarm state
/// (red) with response actions, or a calm "all clear" state.
class AssistantSmokeCard extends StatefulWidget {
  const AssistantSmokeCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantSmokeCard> createState() => _AssistantSmokeCardState();
}

class _AssistantSmokeCardState extends State<AssistantSmokeCard> {
  late bool _alarm;

  @override
  void initState() {
    super.initState();
    final s = widget.device.state;
    _alarm = s['smoke'] == true ||
        s['alarm'] == true ||
        s['state'] == 'alarm' ||
        s['detected'] == true;
  }

  String? get _room => widget.device.room;

  int? get _battery {
    final b = widget.device.state['battery'];
    return b is num ? b.round() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _alarm ? _alarmHero() : _clearHero(),
        if (_alarm) ...[
          const SizedBox(height: 12),
          _actions(context),
          const SizedBox(height: 12),
          _whatFiboDid(),
        ],
        if (_battery != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.battery_full,
                  size: 15, color: AgentColors.inkMuted),
              const SizedBox(width: 6),
              Text('Sensor battery $_battery%',
                  style: CardText.hint.copyWith(color: AgentColors.inkMuted)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _alarmHero() {
    final roomLabel = (_room == null || _room!.isEmpty)
        ? 'just now'
        : '${_titleize(_room!)} · just now';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x59DC2626), blurRadius: 30, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x26FFFFFF)),
            child: const Icon(Icons.local_fire_department, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'SMOKE DETECTED',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(roomLabel,
              style: const TextStyle(
                  fontFamily: 'Geist', fontSize: 14, color: Color(0xD9FFFFFF))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFDC2626)),
                ),
                const SizedBox(width: 6),
                const Text('Alarm active',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clearHero() {
    return AgentCard(
      padding: 24,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF1E3A2C)),
            child: const Icon(Icons.check_circle,
                size: 40, color: Color(0xFF34D399)),
          ),
          const SizedBox(height: 12),
          Text('All Clear', style: CardText.value.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text('No smoke detected',
              style: CardText.muted.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.volume_off,
            label: 'Silence',
            dark: true,
            onTap: () {
              setState(() => _alarm = false);
              widget.onControl('silence', null);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.videocam_outlined,
            label: 'Cameras',
            dark: false,
            onTap: () => Navigator.of(context).pushNamed('/camera/list'),
          ),
        ),
      ],
    );
  }

  // Static narrative of the automated response, per the design. Wire to real
  // automation history when available.
  Widget _whatFiboDid() {
    return AgentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fibo responded',
              style: CardText.muted.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _didRow(Icons.meeting_room_outlined, 'Unlocked front door for exit'),
          const SizedBox(height: 10),
          _didRow(Icons.notifications_active_outlined, 'Notified everyone home'),
        ],
      ),
    );
  }

  Widget _didRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF34D399)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontFamily: 'Geist', fontSize: 13, color: AgentColors.ink)),
        ),
      ],
    );
  }

  String _titleize(String id) => id
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: dark ? kAgentDarkGradient : null,
          color: dark ? null : AgentColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: dark ? null : Border.all(color: AgentColors.stroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
          ],
        ),
      ),
    );
  }
}
