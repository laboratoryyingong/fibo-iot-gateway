import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/assistant_controller.dart';
import '../widgets/tool_result_card.dart';

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
            for (final tool in message.tools) ToolResultCard(tool: tool),
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
            else if (message.streaming && message.tools.isEmpty)
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

class _Composer extends StatefulWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _listening = false;
  String _base = '';

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_ready) {
      _ready = await _speech.initialize(
        onStatus: (s) {
          if (mounted && (s == 'done' || s == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!_ready) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Voice input is unavailable on this device.'),
          ));
        }
        return;
      }
    }
    _base = widget.controller.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        final next = _base.isEmpty ? words : '$_base $words';
        widget.controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _listening ? SpaceColors.accentStart : SpaceColors.stroke,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              onSubmitted: (_) => widget.onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                color: SpaceColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _listening ? 'Listening…' : 'Message your home…',
                hintStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  color: SpaceColors.textMuted,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleListen,
            icon: Icon(
              _listening ? Icons.mic : Icons.mic_none_rounded,
              color: _listening ? SpaceColors.accentStart : SpaceColors.textMuted,
            ),
          ),
          IconButton(
            onPressed: widget.onSend,
            icon: const Icon(Icons.send_rounded, color: SpaceColors.accentStart),
          ),
        ],
      ),
    );
  }
}
