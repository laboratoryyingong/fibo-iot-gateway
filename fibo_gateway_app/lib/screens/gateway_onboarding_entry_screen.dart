import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:fibo_core/theme/app_decorations.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/pairing_action_button.dart';
import '../widgets/pairing_gradient_panel.dart';
import 'gateway_qr_scan_screen.dart';

class GatewayOnboardingEntryScreen extends StatelessWidget {
  const GatewayOnboardingEntryScreen({super.key});

  Future<void> _handleBack(BuildContext context) async {
    final didPop = await Navigator.of(context).maybePop();
    if (didPop || !context.mounted) return;

    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Gateway Setup',
              onLeadingTap: () => _handleBack(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 162,
                      height: 162,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E5FC),
                        borderRadius: BorderRadius.circular(81),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.router_outlined,
                          size: 80,
                          color: PairingTokens.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Set Up Gateway',
                      style: PairingTextStyles.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect your gateway and control devices faster',
                      textAlign: TextAlign.center,
                      style: PairingTextStyles.caption.copyWith(
                        color: PairingTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const PairingGradientPanel(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: _GatewayStepsCard(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  PairingActionButton(
                    text: 'Set Up',
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/gateway/qr-scan'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(
                      '/gateway/qr-scan',
                      arguments: const GatewayQrScanScreenArgs(
                        initialManual: true,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'I already have one',
                        style: PairingTextStyles.body.copyWith(
                          color: PairingTokens.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GatewayStepsCard extends StatelessWidget {
  const _GatewayStepsCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'In 3 steps:',
            style: TextStyle(
              fontFamily: PairingTokens.fontPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PairingTokens.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          _GatewayStep(index: '1', text: 'Power on your gateway'),
          SizedBox(height: 10),
          _GatewayStep(index: '2', text: 'Bind it securely'),
          SizedBox(height: 10),
          _GatewayStep(index: '3', text: 'Start managing devices'),
        ],
      ),
    );
  }
}

class _GatewayStep extends StatelessWidget {
  const _GatewayStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: PairingTokens.accentPrimary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              index,
              style: PairingTextStyles.small.copyWith(
                color: PairingTokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: PairingTextStyles.caption)),
      ],
    );
  }
}
