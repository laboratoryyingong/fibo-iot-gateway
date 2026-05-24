import 'package:flutter/material.dart';

import '../screens/assistant_models.dart';
import '../theme/space_tokens.dart';
import 'assistant_tool_chip.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: isUser ? SpaceColors.bgElevated : SpaceColors.bgSurface,
            borderRadius: BorderRadius.circular(18),
            border: isUser ? null : Border.all(color: SpaceColors.stroke),
          ),
          child: _content(isUser),
        ),
      ),
    );
  }

  Widget _content(bool isUser) {
    if (isUser) {
      return Text(
        message.text,
        style: SpaceTextStyles.cardMeta.copyWith(
          color: SpaceColors.textPrimary,
          fontSize: 15,
        ),
      );
    }

    final children = <Widget>[];
    for (final chip in message.toolCalls) {
      children.add(AssistantToolChip(chip: chip));
    }
    if (message.text.isNotEmpty) {
      children.add(Text(
        message.text,
        style: SpaceTextStyles.cardMeta.copyWith(
          color: SpaceColors.textPrimary,
          fontSize: 15,
          height: 1.4,
        ),
      ));
    } else if (message.isStreaming) {
      children.add(const _ThinkingDots());
    }

    if (children.isEmpty) {
      // Empty assistant bubble (unlikely but defensive).
      return const _ThinkingDots();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final offset = (_ctrl.value - i * 0.18) % 1.0;
              final opacity = 0.35 + 0.65 * (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpaceColors.textMuted.withValues(alpha: opacity),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
