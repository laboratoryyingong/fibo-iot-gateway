import 'package:flutter/material.dart';

import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';
import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/app_decorations.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../services/ble_hub_transport.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/pairing_action_button.dart';
import 'gateway_provisioning_flow.dart';

enum _DiscoveryStep { scanning, connecting, securing, reading }

enum _DiscoveryError { notFound, wrongPop, connectFailed, serialMismatch }

/// Finds the hub over BLE and establishes the encrypted provisioning session
/// (ble-provisioning-protocol.md §7.1 steps 3–4), then hands the live session
/// to the network screen.
class GatewayDiscoveryScreen extends StatefulWidget {
  const GatewayDiscoveryScreen({super.key});

  @override
  State<GatewayDiscoveryScreen> createState() => _GatewayDiscoveryScreenState();
}

class _GatewayDiscoveryScreenState extends State<GatewayDiscoveryScreen> {
  HubProvisioningFlow? _flow;
  _DiscoveryStep _step = _DiscoveryStep.scanning;
  _DiscoveryError? _error;
  String? _errorDetail;
  int _attempt = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flow != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HubProvisioningFlow) {
      _flow = args;
      _run();
    }
  }

  Future<void> _run() async {
    final flow = _flow!;
    final attempt = ++_attempt;
    setState(() {
      _step = _DiscoveryStep.scanning;
      _error = null;
      _errorDetail = null;
    });

    HubProvisioningSession? session;
    try {
      final device = await BleHubTransport.scanForHub(
        bleName: flow.label.bleName,
      );
      if (!mounted || attempt != _attempt) return;
      if (device == null) {
        setState(() => _error = _DiscoveryError.notFound);
        return;
      }

      setState(() => _step = _DiscoveryStep.connecting);
      final transport = await BleHubTransport.connect(device);
      session = HubProvisioningSession(transport);
      if (!mounted || attempt != _attempt) {
        await session.close();
        return;
      }

      setState(() => _step = _DiscoveryStep.securing);
      await session.establish(flow.label.pop);
      if (!mounted || attempt != _attempt) {
        await session.close();
        return;
      }

      setState(() => _step = _DiscoveryStep.reading);
      final info = await session.readInfo();
      if (!mounted || attempt != _attempt) {
        await session.close();
        return;
      }

      // Verify serial == sn from the QR (§6.2). Dev boards may have an empty
      // serial on either side; only a real mismatch is fatal.
      if (flow.label.serial.isNotEmpty &&
          info.serial.isNotEmpty &&
          flow.label.serial != info.serial) {
        await session.close();
        setState(() => _error = _DiscoveryError.serialMismatch);
        return;
      }

      flow.session = session;
      flow.info = info;
      await Navigator.of(context).pushReplacementNamed(
        '/gateway/network',
        arguments: flow,
      );
    } on Security1Exception {
      await session?.close();
      if (!mounted || attempt != _attempt) return;
      setState(() => _error = _DiscoveryError.wrongPop);
    } on BleHubException catch (e) {
      await session?.close();
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _error = _DiscoveryError.connectFailed;
        _errorDetail = e.message;
      });
    } catch (e) {
      await session?.close();
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _error = _DiscoveryError.connectFailed;
        _errorDetail = '$e';
      });
    }
  }

  @override
  void dispose() {
    // Invalidate any in-flight attempt; sessions created after this point are
    // closed by the attempt guard above.
    _attempt++;
    super.dispose();
  }

  (String, String) _statusCopy() {
    final flow = _flow;
    final error = _error;
    if (error != null) {
      switch (error) {
        case _DiscoveryError.notFound:
          return (
            'Hub Not Found',
            flow != null && flow.reconfigure
                ? 'Hold the BOOT button for 3 s until the LED blinks fast, '
                      'then try again.'
                : 'Check that the hub is powered. A fast-blinking LED means '
                      'it is ready to connect.',
          );
        case _DiscoveryError.wrongPop:
          return (
            'Secure Pairing Failed',
            'The PoP code did not match. Re-scan the QR code on the device '
                'label.',
          );
        case _DiscoveryError.serialMismatch:
          return (
            'Wrong Hub',
            'The connected hub reports a different serial than the QR label. '
                'Move closer to your hub and try again.',
          );
        case _DiscoveryError.connectFailed:
          return (
            'Connection Failed',
            'Another phone may be connected (the hub accepts one connection). '
                'Wait a few seconds and retry.\n${_errorDetail ?? ''}',
          );
      }
    }
    switch (_step) {
      case _DiscoveryStep.scanning:
        return (
          'Searching...',
          'Looking for ${_flow?.label.bleName ?? 'your hub'} nearby',
        );
      case _DiscoveryStep.connecting:
        return ('Connecting...', 'Establishing the Bluetooth link');
      case _DiscoveryStep.securing:
        return ('Securing...', 'Verifying the device with your QR code');
      case _DiscoveryStep.reading:
        return ('Almost There...', 'Reading hub status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, caption) = _statusCopy();
    final hasError = _error != null;

    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Find Hub',
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Column(
                  children: [
                    _DiscoveryIllustration(error: hasError),
                    const SizedBox(height: 34),
                    Text(
                      title,
                      style: PairingTextStyles.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: PairingTextStyles.caption.copyWith(
                        color: PairingTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!hasError) _ProgressCard(step: _step),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  if (hasError)
                    PairingActionButton(text: 'Try Again', onPressed: _run),
                  if (hasError) const SizedBox(height: 12),
                  PairingActionButton(
                    text: 'Back to Scan',
                    variant: PairingActionButtonVariant.neutral,
                    onPressed: () => Navigator.of(context).pop(),
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

class _DiscoveryIllustration extends StatelessWidget {
  const _DiscoveryIllustration({required this.error});

  final bool error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PairingTokens.accentPrimary, width: 2),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PairingTokens.accentPrimary,
                ),
                child: Icon(
                  error ? Icons.bluetooth_disabled : Icons.router_outlined,
                  size: 28,
                  color: PairingTokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.step});

  final _DiscoveryStep step;

  @override
  Widget build(BuildContext context) {
    final progress = switch (step) {
      _DiscoveryStep.scanning => 1,
      _DiscoveryStep.connecting => 2,
      _DiscoveryStep.securing => 3,
      _DiscoveryStep.reading => 4,
    };
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Bluetooth setup',
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
              child: Row(
                children: [
                  Expanded(
                    flex: progress,
                    child: Container(color: PairingTokens.accentPrimary),
                  ),
                  Expanded(flex: 5 - progress, child: const SizedBox()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Encrypted with your QR label',
            style: PairingTextStyles.small.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
