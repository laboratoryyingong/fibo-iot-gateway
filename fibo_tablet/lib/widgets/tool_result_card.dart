import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/assistant_controller.dart';

/// Compact card summarising one agent tool call + its result, shown inline in
/// the assistant transcript. Schema-robust: it surfaces a best-effort detail
/// from the tool output without assuming a fixed shape.
class ToolResultCard extends StatelessWidget {
  const ToolResultCard({super.key, required this.tool});

  final ToolResult tool;

  @override
  Widget build(BuildContext context) {
    final error = tool.isError;
    final accent = error ? const Color(0xFFEF6F6F) : SpaceColors.accentStart;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SpaceColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: tool.pending
                ? const CircularProgressIndicator(
                    strokeWidth: 2, color: SpaceColors.accentStart)
                : Icon(
                    error ? Icons.error_outline_rounded : _iconFor(tool.name),
                    size: 20,
                    color: accent,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(),
                  style: SpaceTextStyles.pillTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_detail() case final detail?) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: SpaceTextStyles.pillMeta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title() {
    final label = _humanize(tool.name);
    if (tool.pending) return '$label…';
    return tool.isError ? '$label failed' : label;
  }

  /// Best-effort one-line detail from the tool output.
  String? _detail() {
    final out = tool.output;
    if (out == null) return null;
    for (final key in const ['message', 'summary', 'detail', 'error']) {
      final v = out[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    // A name + a state-ish field is a common control-result shape.
    final name = out['name'] ?? out['device'] ?? out['displayName'];
    final state = out['state'] ?? out['power'] ?? out['status'];
    if (name is String && state != null) return '$name → $state';
    if (name is String) return name;
    return null;
  }

  static String _humanize(String name) {
    final words = name
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return words.isEmpty ? 'Tool' : words;
  }

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('scene')) return Icons.auto_awesome_rounded;
    if (n.contains('control') || n.contains('set') || n.contains('turn')) {
      return Icons.tune_rounded;
    }
    if (n.contains('get') || n.contains('list') || n.contains('status')) {
      return Icons.search_rounded;
    }
    return Icons.bolt_rounded;
  }
}
