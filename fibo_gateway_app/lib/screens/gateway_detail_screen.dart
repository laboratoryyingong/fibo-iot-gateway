import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class GatewayDetailScreen extends StatefulWidget {
  const GatewayDetailScreen({super.key});

  @override
  State<GatewayDetailScreen> createState() => _GatewayDetailScreenState();
}

class _GatewayDetailScreenState extends State<GatewayDetailScreen> {
  GatewayProfile? _gateway;
  ParseUser? _user;
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
      _user = user;
      _gateway = gateway;
      _loading = false;
    });
  }

  Future<void> _restartGateway() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gateway restart has been queued.')),
    );
  }

  Future<void> _firmwareUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firmware update flow will be connected next.'),
      ),
    );
  }

  Future<void> _unbindGateway() async {
    final gateway = _gateway;
    final user = _user;
    if (gateway == null || user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unbind Gateway'),
        content: Text('Remove ${gateway.name} from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unbind'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await GatewayLinkingService.unbindGateway(
      user: user,
      gatewayId: gateway.id,
    );
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unbind gateway right now.')),
      );
      return;
    }

    final hasGateway = await GatewayLinkingService.hasLinkedGateway(user);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      hasGateway
          ? GatewayLinkingService.listRoute
          : GatewayLinkingService.onboardingRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateway = _gateway;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : gateway == null
            ? const Center(child: Text('No gateway selected'))
            : Column(
                children: [
                  _Header(
                    onBack: () => Navigator.of(context).maybePop(),
                    onMore: () => Navigator.of(
                      context,
                    ).pushNamed(GatewayLinkingService.listRoute),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          _HeroCard(gateway: gateway),
                          const SizedBox(height: 16),
                          _StatsRow(gateway: gateway),
                          const SizedBox(height: 16),
                          _InfoCard(gateway: gateway),
                          const SizedBox(height: 16),
                          _SectionLabel('Gateway Actions'),
                          const SizedBox(height: 10),
                          _SettingsCard(
                            onDiagnostics: () =>
                                Navigator.of(context).pushNamed(
                                  GatewayLinkingService.statusRoute,
                                  arguments: gateway.id,
                                ),
                            onFirmwareUpdate: _firmwareUpdate,
                            onRestart: _restartGateway,
                            onUnbind: _unbindGateway,
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderActionButton(icon: Icons.arrow_back, onTap: onBack),
          Text('Gateway Details', style: AppTextStyles.heading20),
          HeaderActionButton(icon: Icons.more_vert, onTap: onMore),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF6BA8E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x404A90D9),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.router_outlined,
                  size: 30,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gateway.name,
                      style: AppTextStyles.heading20.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gateway.location ?? gateway.model,
                      style: AppTextStyles.body13Muted.copyWith(
                        color: AppColors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              _HeroStatusBadge(label: gateway.statusLabel),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Connected · Zigbee Ch.15 · ${gateway.serialNumber}',
            style: AppTextStyles.body13Muted.copyWith(
              color: AppColors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.body13Muted.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${gateway.activeDeviceCount}',
            label: 'Active Devices',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: GatewayLinkingService.linkQualityLabelFor(gateway),
            label: 'Link Quality',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.heading28.copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.body13Muted),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTextStyles.body13Muted.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Model', value: gateway.model, showDivider: true),
          _InfoRow(
            label: 'Firmware',
            value: gateway.firmwareVersion,
            showDivider: true,
          ),
          _InfoRow(
            label: 'Last Seen',
            value: gateway.lastSeenLabel ?? 'Just now',
            showDivider: true,
          ),
          _InfoRow(label: 'Serial Number', value: gateway.serialNumber),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body14),
              Text(value, style: AppTextStyles.body14Muted),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.onDiagnostics,
    required this.onFirmwareUpdate,
    required this.onRestart,
    required this.onUnbind,
  });

  final VoidCallback onDiagnostics;
  final VoidCallback onFirmwareUpdate;
  final VoidCallback onRestart;
  final VoidCallback onUnbind;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.network_check_outlined,
            label: 'Network Diagnostics',
            onTap: onDiagnostics,
            showDivider: true,
          ),
          _ActionRow(
            icon: Icons.upgrade_outlined,
            label: 'Firmware Update',
            onTap: onFirmwareUpdate,
            showDivider: true,
          ),
          _ActionRow(
            icon: Icons.restart_alt_outlined,
            label: 'Restart Gateway',
            onTap: onRestart,
            showDivider: true,
          ),
          _ActionRow(
            icon: Icons.link_off_outlined,
            label: 'Unbind Gateway',
            onTap: onUnbind,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? AppColors.destructive : AppColors.primary;
    final textColor = destructive
        ? AppColors.destructive
        : AppColors.foreground;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: destructive
                        ? AppColors.colorError.withValues(alpha: 0.4)
                        : AppColors.accentBlueSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body14.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: destructive
                      ? AppColors.destructive
                      : AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
