import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UserScenesScreen extends StatelessWidget {
  const UserScenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: const [
            _Header(),
            SizedBox(height: 6),
            Text(
              'Tap a scene to activate it',
              style: AppTextStyles.body14Muted,
            ),
            SizedBox(height: 12),
            _SceneCard(
              title: 'Morning Routine',
              subtitle: 'Turn on lights, open blinds',
              iconColor: AppColors.primary,
            ),
            SizedBox(height: 10),
            _SceneCard(
              title: 'Good Night',
              subtitle: 'Turn off all lights, lock doors',
              iconColor: AppColors.scenePurple,
            ),
            SizedBox(height: 10),
            _SceneCard(
              title: 'Away Mode',
              subtitle: 'Lock all, enable security',
              iconColor: AppColors.dangerStrong,
            ),
            SizedBox(height: 10),
            _SceneCard(
              title: 'Movie Time',
              subtitle: 'Dim lights to 20%, close blinds',
              iconColor: AppColors.successStrong,
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('Scenes', style: AppTextStyles.heading28),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
            child: Icon(Icons.bolt, color: iconColor),
          ),
          const SizedBox(width: 10),
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
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(84, 38),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}
