import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/assistant_controller.dart';

/// The Assistant pane: a big-screen chat with the Claude home agent, streamed
/// from claude_agent_client.
class AssistantPanelScreen extends StatefulWidget {
  const AssistantPanelScreen({super.key});

  @override
  State<AssistantPanelScreen> createState() => _AssistantPanelScreenState();
}

class _AssistantPanelScreenState extends State<AssistantPanelScreen> {
  final _controller = AssistantController();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_autoScroll);
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _controller.send(text);
    _input.clear();
  }

  @override
  void dispose() {
    _controller.removeListener(_autoScroll);
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assistant', style: SpaceTextStyles.sectionTitle),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.messages.isEmpty) return const _EmptyState();
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _controller.messages.length,
                      itemBuilder: (_, i) =>
                          _Bubble(message: _controller.messages[i]),
                    );
                  },
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _Composer(controller: _input, onSend: _send),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_outlined,
              size: 52, color: SpaceColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Ask me to control your home.',
            style: SpaceTextStyles.cardMeta,
          ),
          const SizedBox(height: 6),
          Text(
            '“Turn off the living room lights” · “Goodnight”',
            style: SpaceTextStyles.pillMeta,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: user ? SpaceColors.accentEnd : SpaceColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: user ? null : Border.all(color: SpaceColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final note in message.toolNotes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 14, color: SpaceColors.accentStart),
                    const SizedBox(width: 6),
                    Text(note, style: SpaceTextStyles.pillMeta),
                  ],
                ),
              ),
            if (message.text.isNotEmpty)
              SelectableText(
                message.text,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  height: 1.4,
                  color: SpaceColors.textPrimary,
                ),
              )
            else if (message.streaming && message.toolNotes.isEmpty)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: SpaceColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                color: SpaceColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Message your home…',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  color: SpaceColors.textMuted,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, color: SpaceColors.accentStart),
          ),
        ],
      ),
    );
  }
}
