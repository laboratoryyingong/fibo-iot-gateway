import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class GatewayStatusScreen extends StatefulWidget {
  const GatewayStatusScreen({super.key});

  @override
  State<GatewayStatusScreen> createState() => _GatewayStatusScreenState();
}

class _GatewayStatusScreenState extends State<GatewayStatusScreen> {
  GatewayProfile? _gateway;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gatewayArg = ModalRoute.of(context)?.settings.arguments;
    _load(gatewayArg);
  }

  Future<void> _load(Object? gatewayArg) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    final gateways = await GatewayLinkingService.getLinkedGateways(user);
    GatewayProfile? gateway;
    if (gatewayArg is String) {
      for (final item in gateways) {
        if (item.id == gatewayArg) {
          gateway = item;
          break;
        }
      }
    }
    gateway ??= await GatewayLinkingService.getSelectedGateway(user);

    if (!mounted) return;
    setState(() {
      _gateway = gateway;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gateway = _gateway ?? GatewayLinkingService.suggestedGateway();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          _ErrorCard(gateway: gateway),
                          const SizedBox(height: 14),
                          const _WarningCard(),
                          const SizedBox(height: 14),
                          _SuccessCard(gateway: gateway),
                          const SizedBox(height: 14),
                          const _LoadingCard(),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderActionButton(icon: Icons.arrow_back, onTap: onBack),
          Text('Gateway Status', style: AppTextStyles.heading20),
          const HeaderActionButton(icon: Icons.notifications_none),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    return _StatusContainer(
      background: AppColors.colorError,
      borderColor: AppColors.destructive.withValues(alpha: 0.2),
      shadowColor: const Color(0x20E22525),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.destructive,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Lost',
                      style: AppTextStyles.body16.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.colorErrorForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gateway.name,
                      style: AppTextStyles.body13Muted.copyWith(
                        color: AppColors.colorErrorForeground.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '2 min ago',
                style: AppTextStyles.body13Muted.copyWith(
                  color: AppColors.colorErrorForeground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Unable to reach gateway. Check your network connection or ensure the gateway is powered on.',
            style: AppTextStyles.body14.copyWith(
              color: AppColors.colorErrorForeground,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.colorErrorForeground,
                    foregroundColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.colorErrorForeground,
                    side: BorderSide(
                      color: AppColors.colorErrorForeground.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Diagnose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return _StatusContainer(
      background: AppColors.warning,
      borderColor: AppColors.warningForeground.withValues(alpha: 0.2),
      shadowColor: const Color(0x20C79900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Firmware Update Available',
                  style: AppTextStyles.body16.copyWith(
                    color: AppColors.warningForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'v2.5.0',
                style: AppTextStyles.body14.copyWith(
                  color: AppColors.warningForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A new firmware update is ready to install. Update for better performance and security.',
            style: AppTextStyles.body14.copyWith(
              color: AppColors.warningForeground,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upgrade),
            label: const Text('Update Now'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warningForeground,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    return _StatusContainer(
      background: AppColors.success,
      borderColor: AppColors.successForeground.withValues(alpha: 0.12),
      shadowColor: const Color(0x20005010),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.successForeground.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.successForeground,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gateway Online',
                  style: AppTextStyles.body16.copyWith(
                    color: AppColors.successForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gateway.name} · ${gateway.activeDeviceCount} devices active',
                  style: AppTextStyles.body13Muted.copyWith(
                    color: AppColors.successForeground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _StatusContainer(
      background: AppColors.card,
      borderColor: AppColors.border,
      shadowColor: AppColors.shadowSoft,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync,
              color: AppColors.mutedForeground,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIBO Gateway 2nd Gen',
                  style: AppTextStyles.body16.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 4,
                    color: AppColors.secondary,
                    child: FractionallySizedBox(
                      widthFactor: 0.67,
                      alignment: Alignment.centerLeft,
                      child: Container(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applying update 67%...',
                  style: AppTextStyles.body13Muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusContainer extends StatelessWidget {
  const _StatusContainer({
    required this.background,
    required this.borderColor,
    required this.shadowColor,
    required this.child,
  });

  final Color background;
  final Color borderColor;
  final Color shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
