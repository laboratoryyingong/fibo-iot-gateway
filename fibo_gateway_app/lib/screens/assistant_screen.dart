// V0 SCOPE NOTE:
//   - Direct HTTP to the Claude agent (no auth header, no Parse proxy).
//   - One conversation at a time, in-memory only (no SharedPreferences
//     persistence). Messages and session id are lost on app restart;
//     the agent retains its session on disk but the app forgets the id.
//   - State sync back to SpaceMockStore is best-effort via
//     services/agent_device_map.dart — light devices only for v0.
//   - No voice input, attachments, quick-reply buttons, or real AWS IoT
//     Shadow MQTT subscription. Track those as v1 follow-ups.
//   - Agent has no built-in auth (see docs/claude-agent/INTEGRATING.md §3);
//     the URL in agent_config.local.dart must point at a private host.

import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import '../widgets/assistant_composer.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/space_bottom_bar.dart';
import 'assistant_models.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AssistantStore.instance;
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (_, _) {
            final messages = store.messages;
            final isSending = store.state != AssistantStreamState.idle;
            final showLongChatBanner = store.userTurnCount >= 50;
            return Column(
              children: [
                _Header(
                  onReset: store.resetSession,
                  resetEnabled: messages.isNotEmpty,
                ),
                Expanded(
                  child: messages.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final msg = messages[messages.length - 1 - index];
                            return AssistantMessageBubble(message: msg);
                          },
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
                const SpaceBottomBar(active: SpaceTab.assistant),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onReset, required this.resetEnabled});

  final VoidCallback onReset;
  final bool resetEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Expanded(
              child: Text('Assistant', style: SpaceTextStyles.navTitle),
            ),
            Opacity(
              opacity: resetEnabled ? 1 : 0.35,
              child: InkWell(
                onTap: resetEnabled ? onReset : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SpaceColors.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SpaceColors.stroke),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: SpaceColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: SpaceColors.textPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Talk to your home',
              style: SpaceTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask things like "turn on the living-room light" or "dim the kitchen light to 30%".',
              style: SpaceTextStyles.cardMeta.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A2330),
        borderRadius: BorderRadius.circular(10),
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
              style: SpaceTextStyles.pillMeta.copyWith(
                color: const Color(0xFFFFB4C2),
                fontSize: 12.5,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF324052),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Long conversation — consider starting a new chat.',
              style: SpaceTextStyles.pillMeta.copyWith(
                color: SpaceColors.textPrimary,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onStartFresh,
            style: TextButton.styleFrom(
              foregroundColor: SpaceColors.accentStart,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('New chat'),
          ),
        ],
      ),
    );
  }
}
