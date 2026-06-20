import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';

/// Static Terms of use page.
class LegalTermsScreen extends StatelessWidget {
  const LegalTermsScreen({super.key});

  static const _sections = <(String, String)>[
    (
      '1. Acceptance of Terms',
      'By using the Fibo smart home app you agree to these terms. If you do not '
          'agree, please discontinue use of the app.',
    ),
    (
      '2. Your Account',
      'You are responsible for keeping your account credentials secure and for '
          'all activity that happens under your account. Notify us immediately of '
          'any unauthorised use.',
    ),
    (
      '3. Devices & Control',
      'The app lets you monitor and control connected devices in your home. '
          'Automated actions, scenes, and remote control depend on network and '
          'gateway availability and may be delayed or unavailable at times.',
    ),
    (
      '4. Data',
      'We process device state and account information to provide the service. '
          'We do not sell your personal data. See the Privacy Policy for details.',
    ),
    (
      '5. Limitation of Liability',
      'The app is provided “as is”. Fibo is not liable for damages arising from '
          'device malfunction, connectivity loss, or use of automation features '
          'for safety-critical purposes.',
    ),
    (
      '6. Changes',
      'We may update these terms from time to time. Continued use after an '
          'update constitutes acceptance of the revised terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Terms of use',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  Text(
                    'Last updated: June 2026',
                    style: SpaceTextStyles.pillMeta.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  for (final section in _sections) ...[
                    Text(
                      section.$1,
                      style: SpaceTextStyles.pillTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.$2,
                      style: SpaceTextStyles.pillMeta.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ],
              ),
            ),
          ],
        ),
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
