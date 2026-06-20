import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

/// Shared scaffold for a content pane: a title header plus a body. Section
/// screens start as placeholders and grow real content in later phases.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.note,
  });

  final String title;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SpaceTextStyles.sectionTitle),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: SpaceColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    note,
                    textAlign: TextAlign.center,
                    style: SpaceTextStyles.cardMeta,
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
