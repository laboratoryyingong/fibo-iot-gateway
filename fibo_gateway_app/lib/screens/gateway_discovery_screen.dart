import 'dart:async';

import 'package:flutter/material.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/gateway_info_card.dart';
import '../widgets/pairing_action_button.dart';
import 'gateway_binding_screen.dart';

enum GatewayDiscoveryMode { autoScan, enterCode }

class GatewayDiscoveryScreenArgs {
  const GatewayDiscoveryScreenArgs({
    this.initialMode = GatewayDiscoveryMode.autoScan,
  });

  final GatewayDiscoveryMode initialMode;
}

class GatewayDiscoveryScreen extends StatefulWidget {
  const GatewayDiscoveryScreen({super.key});

  @override
  State<GatewayDiscoveryScreen> createState() => _GatewayDiscoveryScreenState();
}

class _GatewayDiscoveryScreenState extends State<GatewayDiscoveryScreen> {
  final _codeController = TextEditingController(text: 'A1B2C3');

  Timer? _scanTimer;
  final List<GatewayProfile> _candidates =
      GatewayLinkingService.mockDiscoveryCandidates();
  GatewayDiscoveryMode _mode = GatewayDiscoveryMode.autoScan;
  GatewayProfile? _discoveredGateway;
  bool _initialArgsApplied = false;
  int _scanIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialArgsApplied) return;
    _initialArgsApplied = true;
    final args =
        ModalRoute.of(context)?.settings.arguments
            as GatewayDiscoveryScreenArgs?;
    _mode = args?.initialMode ?? GatewayDiscoveryMode.autoScan;
    if (_mode == GatewayDiscoveryMode.autoScan) {
      _startAutoScan();
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startAutoScan() {
    _scanTimer?.cancel();
    setState(() => _discoveredGateway = null);
    _scanTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final gateway = _candidates[_scanIndex % _candidates.length];
      _scanIndex += 1;
      setState(() => _discoveredGateway = gateway);
    });
  }

  void _switchMode(GatewayDiscoveryMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == GatewayDiscoveryMode.autoScan) {
      _startAutoScan();
    } else {
      _scanTimer?.cancel();
    }
  }

  void _goToBinding(GatewayProfile gateway) {
    Navigator.of(context).pushNamed(
      '/gateway/binding',
      arguments: GatewayBindingScreenArgs(gateway: gateway),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAutoMode = _mode == GatewayDiscoveryMode.autoScan;
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Find Gateway',
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Column(
                  children: [
                    _ModeTabs(activeMode: _mode, onChanged: _switchMode),
                    const SizedBox(height: 36),
                    const _DiscoveryIllustration(),
                    const SizedBox(height: 34),
                    if (isAutoMode) ...[
                      Text(
                        'Scanning...',
                        style: PairingTextStyles.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose Auto Scan to find your gateway',
                        textAlign: TextAlign.center,
                        style: PairingTextStyles.caption.copyWith(
                          color: PairingTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _ScanProgressCard(),
                      const SizedBox(height: 20),
                      if (_discoveredGateway != null)
                        GatewayInfoCard(gateway: _discoveredGateway!),
                    ] else ...[
                      Text(
                        'Enter Gateway Code',
                        style: PairingTextStyles.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Use the 6-character code on your gateway label',
                        textAlign: TextAlign.center,
                        style: PairingTextStyles.caption.copyWith(
                          color: PairingTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ManualCodeCard(controller: _codeController),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  PairingActionButton(
                    text: isAutoMode
                        ? (_discoveredGateway == null
                              ? 'Scanning...'
                              : 'Claim Gateway')
                        : 'Continue',
                    onPressed: isAutoMode
                        ? (_discoveredGateway == null
                              ? () {}
                              : () => _goToBinding(_discoveredGateway!))
                        : () => _goToBinding(
                            GatewayLinkingService.gatewayFromCode(
                              _codeController.text,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  PairingActionButton(
                    text: isAutoMode ? 'Scan Again' : 'Use Auto Scan',
                    variant: PairingActionButtonVariant.neutral,
                    onPressed: isAutoMode
                        ? _startAutoScan
                        : () => _switchMode(GatewayDiscoveryMode.autoScan),
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

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.activeMode, required this.onChanged});

  final GatewayDiscoveryMode activeMode;
  final ValueChanged<GatewayDiscoveryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Auto Scan',
            active: activeMode == GatewayDiscoveryMode.autoScan,
            onTap: () => onChanged(GatewayDiscoveryMode.autoScan),
          ),
          const SizedBox(width: 4),
          _ModeTab(
            label: 'Enter Code',
            active: activeMode == GatewayDiscoveryMode.enterCode,
            onTap: () => onChanged(GatewayDiscoveryMode.enterCode),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: active ? PairingTokens.accentPrimary : AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: PairingTextStyles.small.copyWith(
              color: active
                  ? PairingTokens.textPrimary
                  : PairingTokens.textMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryIllustration extends StatelessWidget {
  const _DiscoveryIllustration();

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
                child: const Icon(
                  Icons.router_outlined,
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

class _ScanProgressCard extends StatelessWidget {
  const _ScanProgressCard();

  @override
  Widget build(BuildContext context) {
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
            'Auto scan mode',
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
                    flex: 3,
                    child: Container(color: PairingTokens.accentPrimary),
                  ),
                  const Expanded(flex: 1, child: SizedBox()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Usually under 60s',
            style: PairingTextStyles.small.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCodeCard extends StatelessWidget {
  const _ManualCodeCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gateway Code',
            style: PairingTextStyles.caption.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: PairingTextStyles.body.copyWith(letterSpacing: 1.2),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              hintText: 'A1B2C3',
              hintStyle: PairingTextStyles.body.copyWith(
                color: PairingTokens.textMuted,
              ),
              suffixIcon: const Icon(
                Icons.qr_code_2_outlined,
                color: PairingTokens.textMuted,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Letters and numbers only',
            style: PairingTextStyles.small.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
