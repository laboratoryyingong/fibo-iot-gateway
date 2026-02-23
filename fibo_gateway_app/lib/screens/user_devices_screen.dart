import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class UserDevicesScreen extends StatelessWidget {
  const UserDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Devices', style: AppTextStyles.heading28),
                  const HeaderActionButton(icon: Icons.notifications),
                ],
              ),
            ),
            const _SearchBar(),
            const _FilterTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _DeviceCard(
                    icon: Icons.lightbulb,
                    title: 'Living Room Light',
                    subtitle: 'On · 80%',
                    statusColor: AppColors.successStrong,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/user/device-detail'),
                  ),
                  const SizedBox(height: 10),
                  _DeviceCard(
                    icon: Icons.thermostat,
                    title: 'Thermostat',
                    subtitle: '22°C · Heating',
                    statusColor: AppColors.successStrong,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/user/device-detail'),
                  ),
                  const SizedBox(height: 10),
                  _DeviceCard(
                    icon: Icons.lock,
                    title: 'Front Door Lock',
                    subtitle: 'Locked',
                    statusColor: AppColors.successStrong,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/user/device-detail'),
                  ),
                  const SizedBox(height: 10),
                  _DeviceCard(
                    icon: Icons.sensors,
                    title: 'Kitchen Motion Sensor',
                    subtitle: 'Offline',
                    statusColor: AppColors.neutralStrong,
                    muted: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/user/device-detail'),
                  ),
                  const SizedBox(height: 10),
                  _DeviceCard(
                    icon: Icons.blinds,
                    title: 'Bedroom Blinds',
                    subtitle: 'Open',
                    statusColor: AppColors.successStrong,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/user/device-detail'),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 10),
            Text('Search devices...', style: AppTextStyles.body14Muted),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: const [
          _FilterChip(text: 'All (24)', active: true),
          SizedBox(width: 8),
          _FilterChip(text: 'Online (21)'),
          SizedBox(width: 8),
          _FilterChip(text: 'Offline (3)'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.text, this.active = false});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.body13Muted.copyWith(
          color: active ? AppColors.primaryForeground : AppColors.foreground,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusColor,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color statusColor;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppDecorations.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: muted ? AppColors.mutedForeground : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body14),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(subtitle, style: AppTextStyles.body13Muted),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
