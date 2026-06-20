import 'package:flutter/material.dart';

import 'pairing_flow_navigation.dart';
import 'package:fibo_core/theme/app_decorations.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/pairing_action_button.dart';
import '../widgets/pairing_gradient_panel.dart';
import '../widgets/pairing_header.dart';

class PairingStartScreen extends StatelessWidget {
  const PairingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PairingHeader(
              title: 'Add Device',
              onBack: () => dismissPairingFlow(context),
              onClose: () => dismissPairingFlow(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 162,
                      height: 162,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x55314252), Color(0x2A314252)],
                        ),
                        border: Border.all(
                          color: const Color(0x66314252),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(81),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33111A22),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 78,
                          color: PairingTokens.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    Text(
                      'Add New Zigbee Device',
                      style: PairingTextStyles.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Make Sure your device is in Pairing mode\nbefore continuing',
                      style: PairingTextStyles.caption.copyWith(
                        color: PairingTokens.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    const PairingGradientPanel(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: _StepsCard(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: PairingActionButton(
                text: 'Start Searching',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/pairing/searching'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you start:',
            style: TextStyle(
              fontFamily: PairingTokens.fontPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PairingTokens.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          _StepRow(
            index: '1',
            text:
                'Put your Zigbee device close to the gateway (within 2 meters)',
          ),
          SizedBox(height: 10),
          _StepRow(
            index: '2',
            text:
                'Enable pairing mode on your device (usually by pressing and holding the reset button for 5 seconds)',
          ),
          SizedBox(height: 10),
          _StepRow(
            index: '3',
            text:
                'Wait for the device LED to blink, indicating it\'s ready to pair',
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: PairingTokens.accentPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              index,
              style: PairingTextStyles.small.copyWith(
                color: PairingTokens.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: PairingTextStyles.caption)),
      ],
    );
  }
}
