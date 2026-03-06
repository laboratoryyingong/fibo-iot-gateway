import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/header_action_button.dart';

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
                    const _RoomTabs(),
                    const SizedBox(height: 12),
                    _QuickAccessSection(),
                    const SizedBox(height: 20),
                    const _PromoBanner(),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hub, size: 24, color: AppColors.white),
              ),
              const SizedBox(width: 12),
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
                  Text('Zigbee Hub', style: AppTextStyles.heading20),
                  const SizedBox(height: 2),
                  Text('Welcome back, Admin', style: AppTextStyles.body13Muted),
                ],
              ),
            ],
          ),
          const HeaderActionButton(icon: Icons.notifications),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentBlueSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wifi,
              size: 22,
              color: AppColors.accentBlue,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.successForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uptime: 14 days, 6 hours • 24 devices connected',
                  style: AppTextStyles.body13Muted.copyWith(fontSize: 11),
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
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentBlueSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 22, color: AppColors.accentBlue),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading28.copyWith(fontSize: 28)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.body13Muted),
        ],
      ),
    );
  }
}

class _RoomTabs extends StatelessWidget {
  const _RoomTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _RoomTab(label: 'Living Room', active: true),
        SizedBox(width: 8),
        _RoomTab(label: 'Kitchen'),
        SizedBox(width: 8),
        _RoomTab(label: 'Bedroom'),
        SizedBox(width: 8),
        _RoomTab(label: 'Bathroom'),
      ],
    );
  }
}

class _RoomTab extends StatelessWidget {
  const _RoomTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.accentBlueSurface : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.accentBluePanel : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.body13Muted.copyWith(
          color: active ? AppColors.accentBlue : AppColors.mutedBlueText,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
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
              style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'See all',
              style: AppTextStyles.link14.copyWith(
                fontSize: 13,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppDecorations.softCardShadow,
          ),
          child: Column(
            children: [
              _QuickDeviceRow(
                icon: Icons.space_dashboard_outlined,
                title: 'My Spaces',
                subtitle: '4 rooms • 25 devices',
                enabled: true,
                showDivider: true,
                onTap: () => Navigator.of(context).pushNamed('/spaces'),
              ),
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
                borderRadius: BorderRadius.circular(12),
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
        color: isOn ? AppColors.accentBlue : AppColors.secondary,
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accentBlue, Color(0xFF5BA0E8)],
        ),
        boxShadow: AppDecorations.promoShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick remote access',
                  style: AppTextStyles.body16.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Turn right to get fast access to your wireless remote control',
                  style: AppTextStyles.body13Muted.copyWith(
                    color: const Color(0xCCFFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
