import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/header_action_button.dart';

class DevicesListScreen extends StatelessWidget {
  const DevicesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const _SearchBar(),
            const _FilterTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    _DeviceCard(
                      icon: Icons.lightbulb,
                      name: 'Living Room Light',
                      status: 'Online',
                      room: 'Living Room',
                      statusColor: AppColors.success,
                      statusTextColor: AppColors.successForeground,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/device-detail'),
                    ),
                    const SizedBox(height: 12),
                    _DeviceCard(
                      icon: Icons.thermostat,
                      name: 'Thermostat',
                      status: 'Online',
                      room: 'Hallway',
                      statusColor: AppColors.success,
                      statusTextColor: AppColors.successForeground,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/device-detail'),
                    ),
                    const SizedBox(height: 12),
                    _DeviceCard(
                      icon: Icons.lock,
                      name: 'Front Door Lock',
                      status: 'Online',
                      room: 'Entrance',
                      statusColor: AppColors.success,
                      statusTextColor: AppColors.successForeground,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/device-detail'),
                    ),
                    const SizedBox(height: 12),
                    _DeviceCard(
                      icon: Icons.sensors,
                      name: 'Kitchen Motion Sensor',
                      status: 'Offline',
                      room: 'Kitchen',
                      statusColor: AppColors.colorError,
                      statusTextColor: AppColors.colorErrorForeground,
                      iconMuted: true,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/device-detail'),
                    ),
                    const SizedBox(height: 12),
                    _DeviceCard(
                      icon: Icons.blinds,
                      name: 'Bedroom Blinds',
                      status: 'Online',
                      room: 'Bedroom',
                      statusColor: AppColors.success,
                      statusTextColor: AppColors.successForeground,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/device-detail'),
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
              const SizedBox(width: 16),
              Text('Devices', style: AppTextStyles.heading28),
            ],
          ),
          Row(
            children: [
              const HeaderActionButton(icon: Icons.notifications),
              const SizedBox(width: 8),
              HeaderActionButton(
                icon: Icons.add,
                backgroundColor: AppColors.primary,
                iconColor: AppColors.primaryForeground,
                shadow: false,
                onTap: () => Navigator.of(context).pushNamed('/pairing/start'),
              ),
            ],
          ),
        ],
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
        children: [
          _FilterChip(text: 'All (24)', active: true),
          const SizedBox(width: 8),
          const _FilterChip(text: 'Online (21)'),
          const SizedBox(width: 8),
          const _FilterChip(text: 'Offline (3)'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: AppColors.border, width: 1),
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
    required this.name,
    required this.status,
    required this.room,
    required this.statusColor,
    required this.statusTextColor,
    required this.onTap,
    this.iconMuted = false,
  });

  final IconData icon;
  final String name;
  final String status;
  final String room;
  final Color statusColor;
  final Color statusTextColor;
  final VoidCallback onTap;
  final bool iconMuted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDecorations.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 26,
                color: iconMuted
                    ? AppColors.mutedForeground
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body14),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.body13Muted.copyWith(
                            color: statusTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(room, style: AppTextStyles.body13Muted),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
