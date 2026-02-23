import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            const _Header(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Quick Scenes',
              onSeeAll: () => Navigator.of(context).pushNamed('/user/home'),
            ),
            const SizedBox(height: 10),
            const _ScenesRow(),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'My Devices',
              onSeeAll: () => Navigator.of(context).pushNamed('/user/home'),
            ),
            const SizedBox(height: 10),
            _DeviceTile(
              icon: Icons.lightbulb,
              title: 'Living Room Light',
              subtitle: 'On · 80%',
              statusColor: AppColors.successStrong,
              onTap: () =>
                  Navigator.of(context).pushNamed('/user/device-detail'),
            ),
            const SizedBox(height: 10),
            _DeviceTile(
              icon: Icons.thermostat,
              title: 'Thermostat',
              subtitle: '22°C',
              statusColor: AppColors.successStrong,
              onTap: () =>
                  Navigator.of(context).pushNamed('/user/device-detail'),
            ),
            const SizedBox(height: 10),
            _DeviceTile(
              icon: Icons.lock,
              title: 'Front Door Lock',
              subtitle: 'Locked',
              statusColor: AppColors.successStrong,
              onTap: () =>
                  Navigator.of(context).pushNamed('/user/device-detail'),
            ),
            const SizedBox(height: 10),
            _DeviceTile(
              icon: Icons.blinds,
              title: 'Bedroom Blinds',
              subtitle: 'Closed',
              statusColor: AppColors.neutralStrong,
              onTap: () =>
                  Navigator.of(context).pushNamed('/user/device-detail'),
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
    return Row(
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
              child: const Icon(Icons.home, size: 22, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Home', style: AppTextStyles.heading20),
                const SizedBox(height: 2),
                Text('Good evening, User', style: AppTextStyles.body13Muted),
              ],
            ),
          ],
        ),
        const HeaderActionButton(icon: Icons.notifications),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _ScenesRow extends StatelessWidget {
  const _ScenesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SceneChip(
            icon: Icons.wb_sunny,
            text: 'Morning',
            iconColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _SceneChip(
            icon: Icons.nightlight_round,
            text: 'Good Night',
            iconColor: AppColors.scenePurple,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _SceneChip(
            icon: Icons.flight_takeoff,
            text: 'Away',
            iconColor: AppColors.dangerStrong,
          ),
        ),
      ],
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTextStyles.body13Muted.copyWith(
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color statusColor;
  final VoidCallback onTap;

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
              child: Icon(icon, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
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
