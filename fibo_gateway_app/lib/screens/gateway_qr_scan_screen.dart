import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/pairing_action_button.dart';
import 'gateway_provisioning_flow.dart';

class GatewayQrScanScreenArgs {
  const GatewayQrScanScreenArgs({
    this.reconfigure = false,
    this.initialManual = false,
  });

  final bool reconfigure;
  final bool initialManual;
}

/// Entry point of hub provisioning: scan the QR label on the enclosure
/// (`{"v":1,"sn":...,"ble":...,"pop":...}`), or enter the BLE name and PoP
/// manually (development boards without a factory label).
class GatewayQrScanScreen extends StatefulWidget {
  const GatewayQrScanScreen({super.key});

  @override
  State<GatewayQrScanScreen> createState() => _GatewayQrScanScreenState();
}

class _GatewayQrScanScreenState extends State<GatewayQrScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final _bleNameController = TextEditingController(text: 'FIBO-');
  final _popController = TextEditingController();

  bool _reconfigure = false;
  bool _manualMode = false;
  bool _argsApplied = false;
  bool _handlingDetection = false;
  String? _scanHint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as GatewayQrScanScreenArgs?;
    _reconfigure = args?.reconfigure ?? false;
    _manualMode = args?.initialManual ?? false;
  }

  @override
  void dispose() {
    _scanner.dispose();
    _bleNameController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handlingDetection || _manualMode) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final label = HubQrLabel.tryParse(raw);
      if (label == null) {
        setState(() => _scanHint = 'Not a FIBO hub label — try again');
        continue;
      }
      if (!label.isSupportedVersion) {
        setState(
          () => _scanHint =
              'Label version ${label.version} is not supported — '
              'please update the app',
        );
        continue;
      }
      _handlingDetection = true;
      _startFlow(label);
      return;
    }
  }

  void _submitManual() {
    final bleName = _bleNameController.text.trim();
    final pop = _popController.text.trim();
    if (bleName.length <= HubBleContract.namePrefix.length ||
        !bleName.startsWith(HubBleContract.namePrefix)) {
      setState(() => _scanHint = 'Device name looks like FIBO-XXXXXX');
      return;
    }
    if (pop.isEmpty) {
      setState(() => _scanHint = 'Enter the PoP code from the device label');
      return;
    }
    _startFlow(
      HubQrLabel(
        version: HubQrLabel.supportedVersion,
        serial: '',
        bleName: bleName,
        pop: pop,
      ),
    );
  }

  Future<void> _startFlow(HubQrLabel label) async {
    await _scanner.stop();
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      '/gateway/discovery',
      arguments: HubProvisioningFlow(label: label, reconfigure: _reconfigure),
    );
    // Back on this screen: resume scanning for another attempt.
    if (!mounted) return;
    _handlingDetection = false;
    if (!_manualMode) {
      await _scanner.start();
    }
  }

  Future<void> _setManualMode(bool manual) async {
    if (_manualMode == manual) return;
    setState(() {
      _manualMode = manual;
      _scanHint = null;
    });
    if (manual) {
      await _scanner.stop();
    } else {
      await _scanner.start();
    }
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
              title: _reconfigure ? 'Reconfigure Hub' : 'Scan Hub Label',
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    if (_reconfigure) ...[
                      const _ReconfigureBanner(),
                      const SizedBox(height: 20),
                    ],
                    if (!_manualMode) ...[
                      _ScannerViewport(scanner: _scanner, onDetect: _onDetect),
                      const SizedBox(height: 20),
                      Text(
                        'Point the camera at the QR code on the bottom of '
                        'your FIBO hub',
                        textAlign: TextAlign.center,
                        style: PairingTextStyles.caption.copyWith(
                          color: PairingTokens.textMuted,
                        ),
                      ),
                    ] else
                      _ManualEntryCard(
                        bleNameController: _bleNameController,
                        popController: _popController,
                      ),
                    if (_scanHint != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _scanHint!,
                        textAlign: TextAlign.center,
                        style: PairingTextStyles.caption.copyWith(
                          color: const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  if (_manualMode)
                    PairingActionButton(
                      text: 'Connect',
                      onPressed: _submitManual,
                    ),
                  if (_manualMode) const SizedBox(height: 12),
                  PairingActionButton(
                    text: _manualMode ? 'Scan QR Instead' : 'Enter Manually',
                    variant: PairingActionButtonVariant.neutral,
                    onPressed: () => _setManualMode(!_manualMode),
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

class _ScannerViewport extends StatelessWidget {
  const _ScannerViewport({required this.scanner, required this.onDetect});

  final MobileScannerController scanner;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PairingTokens.radiusLg),
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: scanner, onDetect: onDetect),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: PairingTokens.accentPrimary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReconfigureBanner extends StatelessWidget {
  const _ReconfigureBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
      ),
      child: Text(
        'Hold the BOOT button on the hub for 3 seconds until the LED blinks '
        'fast — this opens a 5-minute configuration window.',
        style: PairingTextStyles.caption.copyWith(
          color: PairingTokens.textMuted,
        ),
      ),
    );
  }
}

class _ManualEntryCard extends StatelessWidget {
  const _ManualEntryCard({
    required this.bleNameController,
    required this.popController,
  });

  final TextEditingController bleNameController;
  final TextEditingController popController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(PairingTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the values printed on the device label',
            style: PairingTextStyles.caption.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          _ManualField(
            label: 'Device Name',
            hint: 'FIBO-D4E5F6',
            controller: bleNameController,
          ),
          const SizedBox(height: 14),
          _ManualField(
            label: 'PoP Code',
            hint: 'x7k2mn9p',
            controller: popController,
          ),
        ],
      ),
    );
  }
}

class _ManualField extends StatelessWidget {
  const _ManualField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PairingTextStyles.small.copyWith(
            color: PairingTokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: PairingTextStyles.body.copyWith(letterSpacing: 1.1),
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            hintText: hint,
            hintStyle: PairingTextStyles.body.copyWith(
              color: PairingTokens.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
