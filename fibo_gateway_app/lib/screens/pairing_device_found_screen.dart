import 'package:flutter/material.dart';

import 'pairing_flow_navigation.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/pairing_action_button.dart';
import '../widgets/pairing_gradient_panel.dart';
import '../widgets/pairing_header.dart';

class PairingDeviceFoundScreen extends StatelessWidget {
  const PairingDeviceFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PairingHeader(
              title: 'Device Found',
              onBack: () => dismissPairingFlow(context),
              onClose: () => dismissPairingFlow(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 16, 23, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 295,
                        child: Text(
                          'The QR Code will be detected automatically when it’s positioned within the guidelines',
                          style: PairingTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    const _FoundBanner(),
                    const SizedBox(height: 17),
                    Text(
                      'Select device to pair',
                      style: PairingTextStyles.small.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 21),
                    const _DeviceCard(),
                    const SizedBox(height: 20),
                    const _InputSection(
                      label: 'Device Name',
                      value: 'Living Room Lights',
                    ),
                    const SizedBox(height: 24),
                    const _InputSection(
                      label: 'Assign to Room',
                      value: 'LIving Room',
                      withDropdown: true,
                    ),
                    const SizedBox(height: 124),
                    PairingActionButton(
                      text: 'Pair Device',
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/pairing/success'),
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

class _FoundBanner extends StatelessWidget {
  const _FoundBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 295,
        height: 68,
        child: PairingGradientPanel(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Center(
            child: Text(
              '1 new device found nearby!',
              style: PairingTextStyles.captionBold,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 295,
        height: 66,
        child: PairingGradientPanel(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
          child: Row(
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.lightbulb,
                  size: 24,
                  color: PairingTokens.accentPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zigbee Light Bulb',
                      style: PairingTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Model: ZB-LIGHT-001',
                      style: PairingTextStyles.small.copyWith(
                        color: PairingTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: PairingTokens.accentEnd,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: PairingTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.label,
    required this.value,
    this.withDropdown = false,
  });

  final String label;
  final String value;
  final bool withDropdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PairingTextStyles.title3),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: PairingTokens.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PairingTokens.bgElevated, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: PairingTextStyles.body.copyWith(
                    color: PairingTokens.textMuted,
                  ),
                ),
              ),
              if (withDropdown)
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 24,
                  color: PairingTokens.textMuted,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
