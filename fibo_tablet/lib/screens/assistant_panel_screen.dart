import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fibo_core/theme/assistant_tokens.dart';

import '../state/assistant_controller.dart';
import '../widgets/tool_result_card.dart';

/// The Assistant pane, matching the phone app's chat agent: a hero greeting,
/// accent glow backdrop, and a pill composer with voice + a gradient action
/// button. Streams replies from claude_agent_client.
class AssistantPanelScreen extends StatefulWidget {
  const AssistantPanelScreen({super.key});

  @override
  State<AssistantPanelScreen> createState() => _AssistantPanelScreenState();
}

class _AssistantPanelScreenState extends State<AssistantPanelScreen> {
  final _controller = AssistantController();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _listening = false;
  String _base = '';

  bool get _hasText => _input.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_autoScroll);
    _input.addListener(() => setState(() {}));
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

  void _onAction() {
    if (_controller.sending) {
      _controller.cancel();
    } else if (_listening || !_hasText) {
      _toggleListen();
    } else {
      _send();
    }
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
    _base = _input.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        final next = _base.isEmpty ? words : '$_base $words';
        _input.value = TextEditingValue(
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
  void dispose() {
    _controller.removeListener(_autoScroll);
    if (_listening) _speech.cancel();
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _GlowBackdrop(),
        Column(
          children: [
            _TopBar(
              onNewChat: _controller.newChat,
              enabled: _controller.messages.isNotEmpty && !_controller.sending,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.messages.isEmpty) return const _HeroState();
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _controller.messages.length,
                        itemBuilder: (_, i) =>
                            _Bubble(message: _controller.messages[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _composer(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
        decoration: BoxDecoration(
          color: AgentColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: _listening ? AgentColors.accent : AgentColors.stroke,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextField(
                  controller: _input,
                  style: AgentTextStyles.body.copyWith(fontSize: 16),
                  cursorColor: AgentColors.accent,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: _listening ? 'Listening…' : 'Ask Anything',
                    hintStyle: AgentTextStyles.placeholder,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _toggleListen,
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none_rounded,
                  size: 22,
                  color: _listening ? AgentColors.accent : AgentColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ActionButton(
                sending: _controller.sending,
                listening: _listening,
                hasText: _hasText,
                onTap: _onAction,
              ),
            ),
          ],
        ),
      ),
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

/// Dark circular action button: waveform to dictate, up-arrow to send, stop
/// while listening or streaming.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.sending,
    required this.listening,
    required this.hasText,
    required this.onTap,
  });

  final bool sending;
  final bool listening;
  final bool hasText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (sending || listening) {
      icon = Icons.stop_rounded;
    } else if (hasText) {
      icon = Icons.arrow_upward_rounded;
    } else {
      icon = Icons.graphic_eq_rounded;
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: kAgentDarkGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
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
          color: user ? AgentColors.accentEnd : AgentColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: user ? null : Border.all(color: AgentColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final tool in message.tools) ToolResultCard(tool: tool),
            if (message.text.isNotEmpty)
              SelectableText(message.text, style: AgentTextStyles.body)
            else if (message.streaming && message.tools.isEmpty)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AgentColors.inkMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
