import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ScenesAddTriggerScreen extends StatelessWidget {
  const ScenesAddTriggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: _TypeListCard(
                  children: [
                    _TypeItem(
                      icon: Icons.devices_other,
                      title: 'Device State',
                      description: 'Trigger when a device state changes',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/scenes/select-device'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.schedule,
                      title: 'Schedule',
                      description: 'Trigger at a specific time or interval',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      description: 'Trigger when entering or leaving an area',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.touch_app_outlined,
                      title: 'Manual',
                      description: 'Trigger manually with a button tap',
                      onTap: () => _showComingSoon(context),
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

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This trigger type will be implemented next.'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 22,
                color: AppColors.foreground,
              ),
            ),
          ),
          Text(
            'Add Trigger',
            style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
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

class _TypeListCard extends StatelessWidget {
  const _TypeListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Select Trigger Type',
              style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  const _TypeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body14),
                  const SizedBox(height: 3),
                  Text(description, style: AppTextStyles.body13Muted),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
