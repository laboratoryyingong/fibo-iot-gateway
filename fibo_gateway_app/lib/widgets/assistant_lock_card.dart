import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Door lock control card, mirroring
/// design/fibo_claude_agent.pen › "47. Door Lock".
class AssistantLockCard extends StatefulWidget {
  const AssistantLockCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantLockCard> createState() => _AssistantLockCardState();
}

class _AssistantLockCardState extends State<AssistantLockCard> {
  late bool _locked;

  @override
  void initState() {
    super.initState();
    final s = widget.device.state['state'] ?? widget.device.state['locked'];
    _locked = s == 'locked' || s == true || s == null;
  }

  void _set(bool locked) {
    setState(() => _locked = locked);
    widget.onControl(locked ? 'lock' : 'unlock', null);
  }

  @override
  Widget build(BuildContext context) {
    final ringBg = _locked ? const Color(0xFF1E3A2C) : const Color(0xFF3D2630);
    final ringFg = _locked ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentCard(
          padding: 24,
          child: Column(
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(shape: BoxShape.circle, color: ringBg),
                child: Icon(
                  _locked ? Icons.lock : Icons.lock_open,
                  size: 54,
                  color: ringFg,
                ),
              ),
              const SizedBox(height: 14),
              Text(_locked ? 'Locked' : 'Unlocked',
                  style: CardText.value.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(_locked ? 'Secured' : 'Unlocked',
                  style: CardText.muted.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LockButton(
                icon: Icons.lock,
                label: 'Lock',
                dark: true,
                onTap: () => _set(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LockButton(
                icon: Icons.lock_open,
                label: 'Unlock',
                dark: false,
                onTap: () => _set(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_maybe_outlined,
                size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Unlocking always needs confirmation',
                style: CardText.hint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({
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
    final fg = dark ? Colors.white : const Color(0xFFF87171);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          gradient: dark ? kAgentDarkGradient : null,
          color: dark ? null : AgentColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: dark
              ? null
              : Border.all(color: const Color(0xFF5A3942)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
