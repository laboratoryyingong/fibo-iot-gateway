import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fibo_core/theme/space_tokens.dart';

/// Static support / contact page. Uses the clipboard to copy details (no
/// external launcher dependency).
class SupportContactScreen extends StatelessWidget {
  const SupportContactScreen({super.key});

  static const _email = 'admin@innoau.com.au';
  static const _hours = 'Mon–Fri, 9:00–17:00 (ACST)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Contact',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  Text(
                    'We’re here to help',
                    style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reach the Fibo support team and we’ll get back to you as '
                    'soon as we can.',
                    style: SpaceTextStyles.pillMeta.copyWith(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ContactTile(
                    icon: Icons.email_outlined,
                    label: 'Support email',
                    value: _email,
                    onCopy: () => _copy(context, _email, 'Email copied'),
                  ),
                  const SizedBox(height: 12),
                  _ContactTile(
                    icon: Icons.schedule_outlined,
                    label: 'Support hours',
                    value: _hours,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: SpaceColors.textPrimary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SpaceTextStyles.pillMeta.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(
                Icons.copy_outlined,
                color: SpaceColors.textMuted,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back,
                color: SpaceColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(title, style: SpaceTextStyles.navTitle),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
