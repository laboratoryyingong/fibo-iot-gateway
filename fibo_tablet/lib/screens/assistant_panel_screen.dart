import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fibo_core/assistant_models.dart';
import 'package:fibo_core/theme/assistant_tokens.dart';
import 'package:fibo_core/widgets/assistant_composer.dart';
import 'package:fibo_core/widgets/assistant_message_bubble.dart';

/// The Assistant pane — the exact same chat agent as the phone app: shared
/// AssistantStore, message bubbles (with rich device/scene cards + markdown)
/// and composer, laid out for the landscape tablet.
class AssistantPanelScreen extends StatelessWidget {
  const AssistantPanelScreen({super.key});

  static const _maxWidth = 820.0;

  @override
  Widget build(BuildContext context) {
    final store = AssistantStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final messages = store.messages;
        final isSending = store.state != AssistantStreamState.idle;
        return Stack(
          children: [
            const _GlowBackdrop(),
            Column(
              children: [
                _TopBar(
                  onNewChat: store.resetSession,
                  enabled: messages.isNotEmpty && !isSending,
                ),
                Expanded(
                  child: messages.isEmpty
                      ? const _HeroState()
                      : Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: _maxWidth),
                            child: ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              itemCount: messages.length,
                              itemBuilder: (_, index) => AssistantMessageBubble(
                                message: messages[messages.length - 1 - index],
                              ),
                            ),
                          ),
                        ),
                ),
                if (store.errorText != null) _ErrorBanner(message: store.errorText!),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: AssistantComposer(
                      isSending: isSending,
                      onSend: store.sendMessage,
                      onCancel: store.cancel,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onNewChat, required this.enabled});

  final VoidCallback onNewChat;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          const Spacer(),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: InkWell(
              onTap: enabled ? onNewChat : null,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AgentColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AgentColors.stroke),
                ),
                child: const Icon(Icons.add_comment_outlined,
                    size: 22, color: AgentColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroState extends StatelessWidget {
  const _HeroState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: kAgentDarkGradient,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AgentColors.surface,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 30, color: AgentColors.ink),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Hey! How can I help you today?',
              textAlign: TextAlign.center,
              style: AgentTextStyles.greeting,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AgentColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgentColors.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF6F6F)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AgentTextStyles.cardTitle)),
        ],
      ),
    );
  }
}

/// Subtle accent glow anchored to the bottom of the chat area.
class _GlowBackdrop extends StatelessWidget {
  const _GlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Opacity(
            opacity: 0.22,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Stack(
                children: const [
                  Positioned(
                    left: 120,
                    bottom: -200,
                    child: _GlowCircle(size: 360, color: AgentColors.accent),
                  ),
                  Positioned(
                    right: 120,
                    bottom: -260,
                    child: _GlowCircle(size: 320, color: AgentColors.accentEnd),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
