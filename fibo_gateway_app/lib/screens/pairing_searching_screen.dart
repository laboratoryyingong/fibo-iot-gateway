import 'dart:async';

import 'package:flutter/material.dart';

import 'pairing_flow_navigation.dart';
import '../theme/app_decorations.dart';
import '../theme/pairing_tokens.dart';
import '../widgets/pairing_action_button.dart';
import '../widgets/pairing_gradient_panel.dart';
import '../widgets/pairing_header.dart';

class PairingSearchingScreen extends StatefulWidget {
  const PairingSearchingScreen({super.key});

  @override
  State<PairingSearchingScreen> createState() => _PairingSearchingScreenState();
}

class _PairingSearchingScreenState extends State<PairingSearchingScreen> {
  Timer? _autoContinueTimer;

  @override
  void initState() {
    super.initState();
    _autoContinueTimer = Timer(const Duration(seconds: 4), _goToDeviceFound);
  }

  @override
  void dispose() {
    _autoContinueTimer?.cancel();
    super.dispose();
  }

  void _goToDeviceFound() {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/pairing/found');
  }

  void _dismissPairing() {
    _autoContinueTimer?.cancel();
    dismissPairingFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PairingHeader(
              title: 'Searching',
              onBack: _dismissPairing,
              onClose: _dismissPairing,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                child: Column(
                  children: [
                    const _Radar(),
                    Text(
                      'Searching for devices...',
                      style: PairingTextStyles.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Make sure your device is in pairing mode and close to the gateway',
                      style: PairingTextStyles.caption.copyWith(
                        color: PairingTokens.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 58),
                    const _ProgressCard(),
                    const SizedBox(height: 122),
                    PairingActionButton(
                      text: 'Cancel',
                      onPressed: _dismissPairing,
                      variant: PairingActionButtonVariant.neutral,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF4A90D9).withValues(alpha: 0.2),
            const Color(0xFF4A90D9).withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PairingTokens.accentPrimary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: PairingTokens.accentPrimary,
              ),
              child: const Icon(
                Icons.radar,
                size: 40,
                color: PairingTokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return PairingGradientPanel(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDecorations.softCardShadow,
        ),
        child: Column(
          children: [
            Text(
              'Scanning Zigbee network...',
              style: PairingTextStyles.caption.copyWith(
                color: PairingTokens.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 6,
                color: PairingTokens.bgElevated,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    child: Container(
                      height: 6,
                      color: PairingTokens.accentPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This may take up to 60 seconds',
              style: PairingTextStyles.small.copyWith(
                fontSize: 12,
                color: PairingTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
