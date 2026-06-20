// V0 SCOPE NOTE:
//   - Direct HTTP to the Claude agent (no auth header, no Parse proxy).
//   - One conversation at a time, in-memory only (no SharedPreferences
//     persistence). Messages and session id are lost on app restart;
//     the agent retains its session on disk but the app forgets the id.
//   - State sync back to SpaceMockStore is best-effort via
//     services/agent_device_map.dart — light devices only for v0.
//   - The composer's plus (attachments) and microphone (voice) affordances,
//     plus the top-left menu button, are visual placeholders. Track voice,
//     attachments, and a conversation drawer as v1 follow-ups.
//   - Agent auth is a single shared key (see
//     docs/claude-agent/APP-INTEGRATION.md §2 & §7); set AgentConfig.apiKey,
//     or point the URL at a private host if the server runs open.
//
// UI: redesigned to match design/fibo_claude_agent.pen (warm light "Fibo AI
// chat agent"). Tokens live in theme/assistant_tokens.dart. The shared dark
// SpaceBottomBar is retained so the Assistant stays reachable as a tab.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fibo_core/theme/assistant_tokens.dart';
import '../widgets/assistant_composer.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/space_bottom_bar.dart';
import 'assistant_models.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key, this.showBottomBar = true});

  /// The persistent tab shell renders the bottom bar itself, so embedded
  /// instances suppress their own.
  final bool showBottomBar;

  @override
  Widget build(BuildContext context) {
    final store = AssistantStore.instance;
    return Scaffold(
      backgroundColor: AgentColors.bg,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: store,
          builder: (_, _) {
            final messages = store.messages;
            final isSending = store.state != AssistantStreamState.idle;
            final showLongChatBanner = store.userTurnCount >= 50;
            return Column(
              children: [
                _TopBar(
                  onNewChat: store.resetSession,
                  newChatEnabled: messages.isNotEmpty,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      const _GlowBackdrop(),
                      messages.isEmpty
                          ? const _HeroState()
                          : ListView.builder(
                              reverse: true,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              itemCount: messages.length,
                              itemBuilder: (_, index) {
                                final msg =
                                    messages[messages.length - 1 - index];
                                return AssistantMessageBubble(message: msg);
                              },
                            ),
                    ],
                  ),
                ),
                if (store.errorText != null)
                  _ErrorBanner(message: store.errorText!),
                if (showLongChatBanner)
                  _LongChatBanner(onStartFresh: store.resetSession),
                AssistantComposer(
                  isSending: isSending,
                  onSend: store.sendMessage,
                  onCancel: store.cancel,
                ),
                if (showBottomBar)
                  const SpaceBottomBar(active: SpaceTab.assistant),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onNewChat, required this.newChatEnabled});

  final VoidCallback onNewChat;
  final bool newChatEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          const Spacer(),
          _CircleButton(
            icon: Icons.add_comment_outlined,
            onTap: newChatEnabled ? onNewChat : null,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && icon == Icons.add_comment_outlined ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AgentColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AgentColors.stroke),
          ),
          child: Icon(icon, size: 22, color: AgentColors.ink),
        ),
      ),
    );
  }
}

/// Subtle accent glow anchored to the bottom of the chat area — keeps the hero
/// from feeling flat while staying on the app's dark/purple palette.
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
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Stack(
                children: const [
                  Positioned(
                    left: 30,
                    bottom: -160,
                    child: _GlowCircle(size: 300, color: AgentColors.accent),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -220,
                    child: _GlowCircle(size: 280, color: AgentColors.accentEnd),
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

class _HeroState extends StatelessWidget {
  const _HeroState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          _Logo(),
          SizedBox(height: 22),
          Text(
            'Hey! How can I help you today?',
            textAlign: TextAlign.center,
            style: AgentTextStyles.greeting,
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AgentColors.logoStrokeA, AgentColors.logoStrokeB],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AgentColors.surface,
        ),
        child: const Icon(Icons.auto_awesome,
            size: 30, color: AgentColors.ink),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2630),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB44A66)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Color(0xFFFFB4C2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AgentTextStyles.chip.copyWith(
                color: const Color(0xFFFFB4C2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LongChatBanner extends StatelessWidget {
  const _LongChatBanner({required this.onStartFresh});

  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AgentColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgentColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Long conversation — consider starting a new chat.',
              style: AgentTextStyles.chip.copyWith(color: AgentColors.ink),
            ),
          ),
          TextButton(
            onPressed: onStartFresh,
            style: TextButton.styleFrom(
              foregroundColor: AgentColors.logoStrokeB,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('New chat'),
          ),
        ],
      ),
    );
  }
}
