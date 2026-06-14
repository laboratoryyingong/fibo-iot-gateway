import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Interactive curtain control card, mirroring
/// design/fibo_claude_agent.pen › "46. Curtain". `position` is the open
/// percentage (0 closed → 100 fully open).
class AssistantCurtainCard extends StatefulWidget {
  const AssistantCurtainCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantCurtainCard> createState() => _AssistantCurtainCardState();
}

class _AssistantCurtainCardState extends State<AssistantCurtainCard> {
  late double _position; // 0..100 open

  @override
  void initState() {
    super.initState();
    final p = widget.device.state['position'];
    _position = (p is num ? p.toDouble() : 100.0).clamp(0.0, 100.0);
  }

  void _setPosition(double value, {bool commit = false}) {
    setState(() => _position = value.clamp(0.0, 100.0));
    if (commit) widget.onControl('set_position', {'value': _position.round()});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentCard(
          padding: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Window(openPercent: _position),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_position.round()}% open', style: CardText.value),
                      const SizedBox(height: 2),
                      const Text('Position', style: CardText.hint),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AgentFillSlider(
                value: _position / 100,
                onChanged: (t) => _setPosition(t * 100),
                onChangeEnd: (t) => _setPosition(t * 100, commit: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.keyboard_double_arrow_up_rounded,
                label: 'Open',
                dark: false,
                onTap: () {
                  _setPosition(100);
                  widget.onControl('open', null);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                dark: true,
                onTap: () => widget.onControl('stop', null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.keyboard_double_arrow_down_rounded,
                label: 'Close',
                dark: false,
                onTap: () {
                  _setPosition(0);
                  widget.onControl('close', null);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A simple window with two curtain panels that part as [openPercent] grows.
class _Window extends StatelessWidget {
  const _Window({required this.openPercent});

  final double openPercent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 160,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final panel = w * (100 - openPercent) / 200;
            const fabric = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE7DED0), Color(0xFFCDBFA8)],
            );
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFCFE6FF), Color(0xFFEEF6FF)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 26,
                  top: 22,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(height: 12, color: const Color(0xFFCBD5E1)),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: panel,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: fabric)),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: panel,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: fabric)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: dark ? kAgentDarkGradient : null,
          color: dark ? null : AgentColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: dark ? null : Border.all(color: AgentColors.stroke),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
