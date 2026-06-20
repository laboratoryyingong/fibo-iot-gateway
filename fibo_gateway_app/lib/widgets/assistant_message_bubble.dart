import 'package:flutter/material.dart';

import '../screens/assistant_models.dart';
import 'package:fibo_core/theme/assistant_tokens.dart';
import 'assistant_device_card.dart';
import 'assistant_device_dashboard.dart';
import 'assistant_markdown.dart';
import 'assistant_scenes_card.dart';
import 'assistant_tool_chip.dart';

/// WhatsApp-style chat row for the Fibo AI agent.
///
/// User turns render as a right-aligned dark bubble (per
/// `design/fibo_claude_agent.pen` › "User Bubble"); assistant turns render as a
/// Fibo avatar beside a left bubble, with rich device cards rendered full-width
/// under the avatar.
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.message});

  final ChatMessage message;

  static const _userText = TextStyle(
    fontFamily: 'Geist',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final width = MediaQuery.of(context).size.width;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.78),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            decoration: const BoxDecoration(
              gradient: kAgentDarkGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Text(message.text, style: _userText),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FiboAvatar(),
          const SizedBox(width: 8),
          Flexible(child: _assistantContent(width)),
        ],
      ),
    );
  }

  Widget _assistantContent(double width) {
    final devices = message.deviceDashboard;
    final device = message.deviceControl;
    final scenes = message.scenes;
    final children = <Widget>[];

    for (final chip in message.toolCalls) {
      // The app-fetched cards supersede the agent's own device tool chips.
      if (devices != null && chip.name == 'get_devices') continue;
      if (scenes != null && (chip.name == 'get_scenes' || chip.name == 'run_scene')) {
        continue;
      }
      if (device != null &&
          (chip.name == 'control_device' || chip.name == 'get_device_status')) {
        continue;
      }
      children.add(AssistantToolChip(chip: chip));
    }

    if (message.text.isNotEmpty && device != null) {
      // Device card: keep the concise reply above the controls.
      children.add(_textBubble(message.text, width));
    }

    if (device != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AssistantDeviceCard(device: device),
      ));
    } else if (scenes != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AssistantScenesCard(
          scenes: scenes,
          onRun: (scene) => AssistantStore.instance.runScene(scene.id),
        ),
      ));
    } else if (devices != null) {
      // App-driven dashboard: render the card and hide the raw text reply.
      children.add(AssistantDeviceDashboard(devices: devices));
    } else if (message.dashboardPending || message.scenesPending) {
      children.add(_bubbleWrap(const _ThinkingDots()));
    } else if (message.text.isNotEmpty) {
      children.add(_textBubble(message.text, width));
    } else if (message.isStreaming) {
      children.add(_bubbleWrap(const _ThinkingDots()));
    }

    if (children.isEmpty) {
      return message.isStreaming
          ? _bubbleWrap(const _ThinkingDots())
          : const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Left chat bubble holding the assistant's markdown reply.
  Widget _textBubble(String text, double width) =>
      _bubbleWrap(AssistantMarkdown(text: text), maxWidth: width * 0.74);

  Widget _bubbleWrap(Widget child, {double? maxWidth}) {
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AgentColors.surfaceElevated,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
      ),
      child: child,
    );
    if (maxWidth == null) return Align(alignment: Alignment.centerLeft, child: bubble);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: bubble,
      ),
    );
  }
}

/// Small gradient Fibo avatar shown beside assistant rows.
class _FiboAvatar extends StatelessWidget {
  const _FiboAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AgentColors.logoStrokeA, AgentColors.logoStrokeB],
        ),
      ),
      child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
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
              final opacity =
                  0.3 + 0.7 * (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AgentColors.inkMuted.withValues(alpha: opacity),
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
