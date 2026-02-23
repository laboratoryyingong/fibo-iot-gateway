import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/header_action_button.dart';

class CameraListScreen extends StatelessWidget {
  const CameraListScreen({super.key});

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  _NvrCard(
                    name: 'Zigbee NVR-1',
                    subtitle: '4 channels · Zigbee Ch.15',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/nvr-channels'),
                  ),
                  const SizedBox(height: 12),
                  _CameraCard(
                    name: 'CH1 - Front Gate',
                    subtitle: 'LIVE',
                    online: true,
                    dark: true,
                    cardColor: AppColors.cameraDarkSurface,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 12),
                  _CameraCard(
                    name: 'CH2 - Backyard',
                    subtitle: 'LIVE',
                    online: true,
                    dark: true,
                    cardColor: AppColors.cameraDarkPanel,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 12),
                  _CameraCard(
                    name: 'Living Room Cam',
                    subtitle: 'Online · 1080p',
                    online: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 12),
                  _CameraCard(
                    name: 'Garage Camera',
                    subtitle: 'Offline',
                    online: false,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                ],
              ),
            ),
            const _CameraBottomNav(),
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
              const AppMenuButton(),
              const SizedBox(width: 16),
              Text('Cameras', style: AppTextStyles.heading28),
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
                onTap: () => Navigator.of(context).pushNamed('/camera/add-nvr'),
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
            Text('Search cameras...', style: AppTextStyles.body14Muted),
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
          _FilterChip(text: 'All (8)', active: true),
          SizedBox(width: 8),
          _FilterChip(text: 'Online (6)'),
          SizedBox(width: 8),
          _FilterChip(text: 'NVR'),
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

class _NvrCard extends StatelessWidget {
  const _NvrCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.body14),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.body13Muted),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _StatusDot(color: AppColors.successStrong),
                SizedBox(width: 6),
                _StatusText('Online'),
                SizedBox(width: 6),
                Icon(Icons.chevron_right, color: AppColors.mutedForeground),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.name,
    required this.subtitle,
    required this.online,
    required this.onTap,
    this.dark = false,
    this.cardColor = AppColors.card,
  });

  final String name;
  final String subtitle;
  final bool online;
  final VoidCallback onTap;
  final bool dark;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final statusColor = online
        ? AppColors.successStrong
        : AppColors.dangerStrong;
    final cardBorderColor = dark
        ? AppColors.cameraOverlayWhite20
        : AppColors.border;
    final titleColor = dark ? AppColors.white : AppColors.foreground;
    final subtitleColor = dark
        ? AppColors.cameraTextFaint
        : AppColors.mutedForeground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor, width: 1),
          boxShadow: dark ? null : AppDecorations.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.videocam, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body14.copyWith(color: titleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body13Muted.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            dark
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      online ? 'LIVE' : 'Offline',
                      style: AppTextStyles.body13Muted.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusDot(color: statusColor),
                      const SizedBox(width: 6),
                      _StatusText(online ? 'Online' : 'Offline'),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.body13Muted);
  }
}

class _CameraBottomNav extends StatelessWidget {
  const _CameraBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBar,
            offset: Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => Navigator.of(context).pushNamed('/home'),
          ),
          _NavItem(
            icon: Icons.videocam,
            label: 'Cameras',
            active: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.devices_outlined,
            label: 'Devices',
            onTap: () => Navigator.of(context).pushNamed('/home'),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(context).pushNamed('/camera/settings'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.mutedForeground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.body13Muted.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
