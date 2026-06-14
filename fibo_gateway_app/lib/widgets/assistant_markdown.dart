import 'package:flutter/material.dart';

import '../theme/assistant_tokens.dart';

/// Lightweight Markdown renderer for assistant replies. Handles the constructs
/// the agent actually emits — section headings, **bold** inline spans, bullet
/// and numbered lists, and paragraphs — styled with the chat design tokens.
///
/// Intentionally small (no third-party dependency). Unsupported syntax falls
/// back to readable plain text.
class AssistantMarkdown extends StatelessWidget {
  const AssistantMarkdown({super.key, required this.text});

  final String text;

  static const _base = AgentTextStyles.body;
  static const _heading = TextStyle(
    fontFamily: 'Geist',
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: AgentColors.ink,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    var first = true;

    void addGap(double h) {
      if (!first) blocks.add(SizedBox(height: h));
    }

    for (var raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (!first) blocks.add(const SizedBox(height: 8));
        continue;
      }

      final heading = _headingText(trimmed);
      if (heading != null) {
        addGap(10);
        blocks.add(Text(heading, style: _heading));
        first = false;
        continue;
      }

      final bullet = _bulletText(trimmed);
      if (bullet != null) {
        addGap(4);
        blocks.add(_listItem(marker: '•', content: bullet));
        first = false;
        continue;
      }

      final numbered = _numberedMatch(trimmed);
      if (numbered != null) {
        addGap(4);
        blocks.add(_listItem(marker: '${numbered.$1}.', content: numbered.$2));
        first = false;
        continue;
      }

      addGap(6);
      blocks.add(RichText(text: TextSpan(children: _inline(trimmed, _base))));
      first = false;
    }

    if (blocks.isEmpty) return Text(text, style: _base);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  /// A line that is entirely bold (`**Heading:**`) or a `#`/`##` heading.
  String? _headingText(String line) {
    if (line.startsWith('#')) {
      return line.replaceFirst(RegExp(r'^#{1,6}\s*'), '').replaceAll('**', '');
    }
    if (line.length > 4 &&
        line.startsWith('**') &&
        line.endsWith('**') &&
        '**'.allMatches(line).length == 2) {
      return line.substring(2, line.length - 2);
    }
    return null;
  }

  String? _bulletText(String line) {
    final m = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
    return m?.group(1);
  }

  (String, String)? _numberedMatch(String line) {
    final m = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
    if (m == null) return null;
    return (m.group(1)!, m.group(2)!);
  }

  Widget _listItem({required String marker, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: marker == '•' ? 16 : 22,
            child: Text(marker,
                style: _base.copyWith(color: AgentColors.inkMuted)),
          ),
          Expanded(
            child: RichText(text: TextSpan(children: _inline(content, _base))),
          ),
        ],
      ),
    );
  }

  /// Splits a line into spans, toggling bold on each `**` delimiter.
  List<TextSpan> _inline(String text, TextStyle base) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final bold = i.isOdd;
      spans.add(TextSpan(
        text: parts[i],
        style: bold ? base.copyWith(fontWeight: FontWeight.w700) : base,
      ));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return spans;
  }
}
