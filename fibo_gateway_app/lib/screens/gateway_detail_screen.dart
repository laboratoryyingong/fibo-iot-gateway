import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import 'space_models.dart';

class GatewayDetailScreen extends StatefulWidget {
  const GatewayDetailScreen({super.key});

  @override
  State<GatewayDetailScreen> createState() => _GatewayDetailScreenState();
}

class _GatewayDetailScreenState extends State<GatewayDetailScreen> {
  GatewayProfile? _gateway;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load(ModalRoute.of(context)?.settings.arguments);
  }

  Future<void> _load(Object? gatewayArg) async {
    // Prefer the real gateways from the live home graph; fall back to the
    // locally-stored list when the graph isn't available.
    final graph = SpaceMockStore.instance.homeGraph;
    List<GatewayProfile> gateways;
    if (graph != null && graph.gateways.isNotEmpty) {
      gateways = GatewayLinkingService.realGatewaysFromGraph(graph);
    } else {
      final user = await ParseUser.currentUser() as ParseUser?;
      gateways = await GatewayLinkingService.getLinkedGateways(user);
    }

    GatewayProfile? gateway;
    if (gatewayArg is String) {
      for (final item in gateways) {
        if (item.id == gatewayArg) {
          gateway = item;
          break;
        }
      }
    }
    gateway ??= gateways.isNotEmpty ? gateways.first : null;

    if (!mounted) return;
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    final gateway = _gateway;
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Gateway Details',
              onLeadingTap: () => Navigator.of(context).maybePop(),
              trailingIcon: Icons.more_horiz,
              onTrailingTap: () => Navigator.of(
                context,
              ).pushNamed(GatewayLinkingService.listRoute),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : gateway == null
                  ? const _EmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCard(gateway: gateway),
                          const SizedBox(height: 18),
                          _StatsRow(gateway: gateway),
                          const SizedBox(height: 24),
                          const _SectionLabel('GATEWAY INFORMATION'),
                          const SizedBox(height: 12),
                          _InfoCard(gateway: gateway),
                          const SizedBox(height: 24),
                          const _SectionLabel('GATEWAY ACTIONS'),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            onDiagnostics: () =>
                                Navigator.of(context).pushNamed(
                                  GatewayLinkingService.statusRoute,
                                  arguments: gateway.id,
                                ),
                            onFirmwareUpdate: _firmwareUpdate,
                            onRestart: _restartGateway,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PairingTokens.bgSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.router_outlined,
                color: PairingTokens.textMuted,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No gateway selected',
              style: PairingTextStyles.headline.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a gateway from My Gateways to view details here.',
              textAlign: TextAlign.center,
              style: PairingTextStyles.caption.copyWith(
                color: PairingTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    final subtitle = gateway.location?.isNotEmpty == true
        ? gateway.location!
        : gateway.model;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PairingTokens.accentPrimary, PairingTokens.accentEnd],
        ),
        borderRadius: BorderRadius.circular(PairingTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.router_outlined,
                  size: 28,
                  color: PairingTokens.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gateway.name,
                      style: PairingTextStyles.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: PairingTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              _HeroStatusBadge(gateway: gateway),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroMetaChip(icon: Icons.memory_outlined, label: gateway.model),
              _HeroMetaChip(
                icon: Icons.tag_outlined,
                label: gateway.serialNumber,
              ),
              _HeroMetaChip(
                icon: Icons.schedule_outlined,
                label: gateway.lastSeenLabel ?? 'Just now',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    final color = _gatewayStatusColor(gateway);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            gateway.statusLabel,
            style: PairingTextStyles.small.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white.withValues(alpha: 0.84)),
          const SizedBox(width: 6),
          Text(
            label,
            style: PairingTextStyles.small.copyWith(
              color: AppColors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PairingTokens.bgElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: PairingTextStyles.title2.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: PairingTextStyles.small.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
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
    return Text(
      label,
      style: PairingTextStyles.small.copyWith(
        color: PairingTokens.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
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
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PairingTokens.bgElevated),
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
          _InfoRow(
            label: 'Serial Number',
            value: gateway.serialNumber,
            showDivider: true,
          ),
          _InfoRow(
            label: 'Location',
            value: gateway.location ?? 'Not assigned',
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: PairingTextStyles.caption.copyWith(
                    color: PairingTokens.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: PairingTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: PairingTokens.bgElevated.withValues(alpha: 0.9),
          ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.onDiagnostics,
    required this.onFirmwareUpdate,
    required this.onRestart,
  });

  final VoidCallback onDiagnostics;
  final VoidCallback onFirmwareUpdate;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PairingTokens.bgElevated),
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.network_check_outlined,
            label: 'Network Diagnostics',
            subtitle: 'Check gateway connection and status',
            onTap: onDiagnostics,
            showDivider: true,
          ),
          _ActionRow(
            icon: Icons.upgrade_outlined,
            label: 'Firmware Update',
            subtitle: 'Review available updates for this gateway',
            onTap: onFirmwareUpdate,
            showDivider: true,
          ),
          _ActionRow(
            icon: Icons.restart_alt_outlined,
            label: 'Restart Gateway',
            subtitle: 'Queue a remote restart for the device',
            onTap: onRestart,
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
    required this.subtitle,
    required this.onTap,
    this.showDivider = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const accentColor = PairingTokens.accentPrimary;
    final iconBg = PairingTokens.accentPrimary.withValues(alpha: 0.16);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: PairingTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: PairingTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: PairingTextStyles.small.copyWith(
                          color: PairingTokens.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: PairingTokens.textMuted.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: PairingTokens.bgElevated.withValues(alpha: 0.9),
          ),
      ],
    );
  }
}

Color _gatewayStatusColor(GatewayProfile gateway) {
  switch (gateway.connectionState) {
    case GatewayConnectionState.online:
      return const Color(0xFF59D08A);
    case GatewayConnectionState.offline:
      return PairingTokens.textMuted;
    case GatewayConnectionState.updating:
      return const Color(0xFFF4B740);
    case GatewayConnectionState.error:
      return const Color(0xFFF56A6A);
  }
}
