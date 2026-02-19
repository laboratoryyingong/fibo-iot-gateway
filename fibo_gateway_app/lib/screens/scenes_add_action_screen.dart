import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ScenesAddActionScreen extends StatelessWidget {
  const ScenesAddActionScreen({super.key});

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
                      icon: Icons.tune,
                      title: 'Control Device',
                      description: 'Turn on/off or adjust device settings',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/scenes/select-device'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.notifications_active,
                      title: 'Send Notification',
                      description: 'Send a push notification to your phone',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.hourglass_bottom,
                      title: 'Wait / Delay',
                      description: 'Add a time delay before next action',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _TypeItem(
                      icon: Icons.bolt,
                      title: 'Run Scene',
                      description: 'Execute another scene as an action',
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
        content: Text('This action type will be implemented next.'),
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
            'Add Action',
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
              'Select Action Type',
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
