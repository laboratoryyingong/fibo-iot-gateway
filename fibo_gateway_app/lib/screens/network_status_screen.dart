import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';

class NetworkStatusScreen extends StatelessWidget {
  const NetworkStatusScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onLogout: () => _handleLogout(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: const [
                    _StatsRow(),
                    SizedBox(height: 20),
                    _TopologyCard(),
                    SizedBox(height: 20),
                    _NetworkDetailsCard(),
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
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppMenuButton(onLogout: onLogout),
              const SizedBox(width: 16),
              Text('Network', style: AppTextStyles.heading28),
            ],
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.notifications, size: 22, color: AppColors.foreground),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.refresh, size: 22, color: AppColors.foreground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            value: '24',
            label: 'Total Devices',
            valueColor: AppColors.foreground,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '87%',
            label: 'Link Quality',
            valueColor: Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.heading28.copyWith(color: valueColor, fontSize: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.body13Muted),
        ],
      ),
    );
  }
}

class _TopologyCard extends StatelessWidget {
  const _TopologyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Network Topology', style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 280,
            child: Stack(
              children: const [
                Positioned(
                  top: 20,
                  left: 50,
                  child: _TopologyNode(
                    icon: Icons.router,
                    label: 'Router A',
                    color: AppColors.secondary,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 50,
                  child: _TopologyNode(
                    icon: Icons.router,
                    label: 'Router B',
                    color: AppColors.secondary,
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: _TopologyNode(
                    icon: Icons.hub,
                    label: 'Gateway',
                    color: AppColors.primary,
                    iconColor: AppColors.primaryForeground,
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

class _TopologyNode extends StatelessWidget {
  const _TopologyNode({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor = AppColors.foreground,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.body13Muted.copyWith(color: AppColors.foreground)),
      ],
    );
  }
}

class _NetworkDetailsCard extends StatelessWidget {
  const _NetworkDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Network Details', style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                _InfoRow(label: 'Channel', value: '15'),
                SizedBox(height: 14),
                _InfoRow(label: 'PAN ID', value: '0x1A2B'),
                SizedBox(height: 14),
                _InfoRow(label: 'Extended PAN', value: '0x00158d00...'),
                SizedBox(height: 14),
                _InfoRow(label: 'Coordinator', value: 'Online'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body13Muted),
        Text(value, style: AppTextStyles.body13Muted.copyWith(color: AppColors.foreground)),
      ],
    );
  }
}
