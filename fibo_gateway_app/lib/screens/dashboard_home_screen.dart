import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GatewayStatusCard(),
                    const SizedBox(height: 12),
                    const _MetricsRow(),
                    const SizedBox(height: 20),
                    _QuickAccessSection(),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppMenuButton(
                onLogout: () async {
                  final user = await ParseUser.currentUser() as ParseUser?;
                  await user?.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zigbee Hub',
                    style: AppTextStyles.heading20.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text('Welcome back, Admin', style: AppTextStyles.body13Muted),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications,
              size: 22,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayStatusCard extends StatelessWidget {
  const _GatewayStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.wifi,
              size: 24,
              color: AppColors.successForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gateway Online',
                  style: AppTextStyles.body16.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uptime: 14 days, 6 hours • 24 devices connected',
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MetricCard(
            icon: Icons.devices,
            value: '24',
            label: 'Devices',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(icon: Icons.speed, value: '98%', label: 'Network'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.bolt,
            value: '12',
            label: 'Automations',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

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
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading24),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.body13Muted),
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Access',
              style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('See all', style: AppTextStyles.link14.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              _QuickDeviceRow(
                icon: Icons.videocam,
                title: 'Camera Center',
                subtitle: '6 online streams',
                enabled: true,
                showDivider: true,
                onTap: () => Navigator.of(context).pushNamed('/camera/list'),
              ),
              _QuickDeviceRow(
                icon: Icons.lightbulb,
                title: 'Living Room Light',
                subtitle: 'Online • Living Room',
                enabled: true,
                showDivider: true,
              ),
              _QuickDeviceRow(
                icon: Icons.router,
                title: 'Zigbee Router',
                subtitle: 'Online • Hallway',
                enabled: true,
                showDivider: true,
              ),
              _QuickDeviceRow(
                icon: Icons.lock,
                title: 'Front Door Lock',
                subtitle: 'Online • Entrance',
                enabled: true,
                showDivider: true,
              ),
              _QuickDeviceRow(
                icon: Icons.sensors,
                title: 'Kitchen Motion Sensor',
                subtitle: 'Offline • Kitchen',
                enabled: false,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickDeviceRow extends StatelessWidget {
  const _QuickDeviceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.showDivider,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body14),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.body13Muted),
                ],
              ),
            ),
            _MiniToggle(isOn: enabled),
          ],
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: isOn ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Align(
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
