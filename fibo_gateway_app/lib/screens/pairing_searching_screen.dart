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

class _Radar extends StatefulWidget {
  const _Radar();

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glowScale = 0.94 + (_pulse.value * 0.1);
        final glowAlpha = 0.12 + (_pulse.value * 0.18);
        final coreScale = 0.95 + (_pulse.value * 0.08);

        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        PairingTokens.accentPrimary.withValues(
                          alpha: glowAlpha,
                        ),
                        PairingTokens.accentPrimary.withValues(
                          alpha: glowAlpha * 0.6,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: coreScale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PairingTokens.accentPrimary.withValues(
                      alpha: 0.88 + (_pulse.value * 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PairingTokens.accentPrimary.withValues(
                          alpha: 0.2 + (_pulse.value * 0.28),
                        ),
                        blurRadius: 24,
                        spreadRadius: 2 + (_pulse.value * 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.radar,
                    size: 40,
                    color: PairingTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
