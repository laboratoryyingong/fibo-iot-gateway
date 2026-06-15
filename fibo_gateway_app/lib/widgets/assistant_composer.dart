import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/assistant_tokens.dart';

/// Pill composer for the Fibo AI chat agent.
///
/// Layout mirrors `design/fibo_claude_agent.pen` › "Search Bar": a dark circular
/// plus button, then a rounded input pill holding the text field, a microphone
/// glyph, and a dark circular action button.
///
/// Voice: the mic glyph and the trailing button both start/stop on-device
/// dictation via `speech_to_text`, streaming the transcript into the field.
/// The plus (attachments) button remains a v0 placeholder.
class AssistantComposer extends StatefulWidget {
  const AssistantComposer({
    super.key,
    required this.isSending,
    required this.onSend,
    required this.onCancel,
  });

  final bool isSending;
  final ValueChanged<String> onSend;
  final VoidCallback onCancel;

  @override
  State<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends State<AssistantComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _hasText = false;
  bool _speechReady = false;
  bool _listening = false;
  String _base = ''; // text already in the field when dictation started

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next != _hasText) {
      setState(() => _hasText = next);
    }
  }

  void _submit() {
    if (widget.isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  // --- Voice dictation -----------------------------------------------------

  Future<void> _toggleListen() async {
    if (widget.isSending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!_speechReady) {
        _showMessage('Voice input is unavailable on this device.');
        return;
      }
    }

    _base = _controller.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        final next = _base.isEmpty ? words : '$_base $words';
        _controller.value = TextEditingValue(
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

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  void _onActionTap() {
    if (widget.isSending) {
      widget.onCancel();
    } else if (_listening || !_hasText) {
      _toggleListen();
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sending = widget.isSending;

    return Container(
      color: AgentColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
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
                      padding: const EdgeInsets.only(bottom: 10, top: 6),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: AgentTextStyles.body.copyWith(fontSize: 16),
                        cursorColor: AgentColors.accent,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          hintText: _listening ? 'Listening…' : 'Ask Anything',
                          hintStyle: AgentTextStyles.placeholder,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _toggleListen,
                      child: Icon(
                        _listening ? Icons.mic : Icons.mic_none_rounded,
                        size: 20,
                        color: _listening ? AgentColors.accent : AgentColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    sending: sending,
                    listening: _listening,
                    hasText: _hasText,
                    onTap: _onActionTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark circular action button at the trailing edge of the input pill.
///
/// Idle shows a waveform (tap to dictate), a stop glyph while listening or
/// streaming, and an up-arrow once text is entered.
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
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          gradient: kAgentDarkGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}
