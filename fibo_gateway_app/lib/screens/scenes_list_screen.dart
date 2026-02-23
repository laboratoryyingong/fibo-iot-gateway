import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/header_action_button.dart';

class ScenesListScreen extends StatelessWidget {
  const ScenesListScreen({super.key});

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
            const _FilterTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _SceneCard(
                    title: 'Temperature Control',
                    active: true,
                    triggerText: 'When temperature < 24°C',
                    actionText: 'Turn on AC → Heat mode 26°C',
                    devicesText: '2 devices',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/scenes/detail'),
                  ),
                  const SizedBox(height: 12),
                  _SceneCard(
                    title: 'Night Mode',
                    active: true,
                    triggerText: 'Every day at 10:00 PM',
                    actionText: 'Dim all lights to 20%',
                    devicesText: '5 devices',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/scenes/detail'),
                  ),
                  const SizedBox(height: 12),
                  _SceneCard(
                    title: 'Security Alert',
                    active: false,
                    triggerText: 'When door sensor triggered',
                    actionText: 'Send notification + Turn on lights',
                    devicesText: '3 devices',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/scenes/detail'),
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
              Text('Scenes', style: AppTextStyles.heading28),
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
                onTap: () => Navigator.of(context).pushNamed('/scenes/detail'),
              ),
            ],
          ),
        ],
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
          _FilterChip(text: 'All (5)', active: true),
          SizedBox(width: 8),
          _FilterChip(text: 'Active (3)'),
          SizedBox(width: 8),
          _FilterChip(text: 'Inactive (2)'),
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

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.title,
    required this.active,
    required this.triggerText,
    required this.actionText,
    required this.devicesText,
    required this.onTap,
  });

  final String title;
  final bool active;
  final String triggerText;
  final String actionText;
  final String devicesText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = active
        ? AppColors.successForeground
        : AppColors.neutralStrong;
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body14),
                      const SizedBox(height: 4),
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
                          active ? 'Active' : 'Inactive',
                          style: AppTextStyles.body13Muted.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _MiniToggle(isOn: active),
              ],
            ),
            const SizedBox(height: 12),
            _LineItem(icon: Icons.play_arrow, text: triggerText),
            const SizedBox(height: 8),
            _LineItem(icon: Icons.flash_on, text: actionText),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.devices,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Text(devicesText, style: AppTextStyles.body13Muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.body13Muted)),
      ],
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
