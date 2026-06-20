import 'package:flutter/material.dart';

import 'package:fibo_core/theme/assistant_tokens.dart';

/// Shared primitives for the in-chat device control cards
/// (design/fibo_claude_agent.pen device screens). Keeps the per-device cards
/// thin and visually consistent.

const kCardAccent = AgentColors.accent; // #7773FA
const kCardTrackGrey = AgentColors.surfaceElevated; // dark track
const kCardChipBg = AgentColors.surfaceElevated; // dark chip/badge

/// Dark rounded card matching the app surfaces.
class AgentCard extends StatelessWidget {
  const AgentCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AgentColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AgentColors.stroke),
      ),
      child: child,
    );
  }
}

/// Header row: icon + label on the left, a value on the right.
class AgentCardHeader extends StatelessWidget {
  const AgentCardHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AgentColors.ink,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 18, color: AgentColors.inkMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AgentColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Grey track with a coloured fill and a white knob.
class AgentFillSlider extends StatelessWidget {
  const AgentFillSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.color = kCardAccent,
  });

  final double value; // 0..1
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(double dx, {bool commit = false}) {
          final t = (dx / width).clamp(0.0, 1.0);
          commit ? onChangeEnd(t) : onChanged(t);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition.dx, commit: true),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          onHorizontalDragEnd: (_) => onChangeEnd(value),
          child: SizedBox(
            height: 22,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: kCardTrackGrey,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  left: (value.clamp(0.0, 1.0) * width - 11)
                      .clamp(0.0, width - 22),
                  child: const AgentKnob(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gradient track with a white knob (e.g. colour temperature).
class AgentGradientSlider extends StatelessWidget {
  const AgentGradientSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    required this.gradient,
  });

  final double value; // 0..1
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(double dx, {bool commit = false}) {
          final t = (dx / width).clamp(0.0, 1.0);
          commit ? onChangeEnd(t) : onChanged(t);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition.dx, commit: true),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          onHorizontalDragEnd: (_) => onChangeEnd(value),
          child: SizedBox(
            height: 22,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: gradient,
                  ),
                ),
                Positioned(
                  left: (value.clamp(0.0, 1.0) * width - 11)
                      .clamp(0.0, width - 22),
                  child: const AgentKnob(bordered: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AgentKnob extends StatelessWidget {
  const AgentKnob({super.key, this.bordered = false});

  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: kCardTrackGrey) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x330F172A), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

/// Standard text styles used inside the cards.
class CardText {
  static const title = TextStyle(
    fontFamily: 'Geist',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AgentColors.ink,
  );
  static const value = TextStyle(
    fontFamily: 'Geist',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AgentColors.ink,
  );
  static const hint = TextStyle(
    fontFamily: 'Geist',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF94A3B8),
  );
  static const muted = TextStyle(
    fontFamily: 'Geist',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AgentColors.inkMuted,
  );
}
