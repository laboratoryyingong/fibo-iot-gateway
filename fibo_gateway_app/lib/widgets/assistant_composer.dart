import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';

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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final sending = widget.isSending;
    final canSend = !sending && _hasText;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(color: SpaceColors.bgBase),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: SpaceColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SpaceColors.stroke),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: SpaceTextStyles.cardMeta.copyWith(
                  color: SpaceColors.textPrimary,
                  fontSize: 15,
                ),
                cursorColor: SpaceColors.accentStart,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                inputFormatters: const [],
                onSubmitted: (_) {
                  if (canSend) _submit();
                },
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Ask the assistant…',
                  hintStyle: SpaceTextStyles.cardMeta.copyWith(
                    color: SpaceColors.textMuted,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            sending: sending,
            enabled: canSend || sending,
            onTap: sending ? widget.onCancel : _submit,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.sending,
    required this.enabled,
    required this.onTap,
  });

  final bool sending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : SpaceColors.bgElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            sending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
            color: SpaceColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
