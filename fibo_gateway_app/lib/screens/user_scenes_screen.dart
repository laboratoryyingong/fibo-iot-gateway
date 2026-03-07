import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';
import 'scenes_models.dart';

class UserScenesScreen extends StatelessWidget {
  const UserScenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                const _Header(),
                const SizedBox(height: 6),
                const Text(
                  'Tap a scene to activate it',
                  style: AppTextStyles.body14Muted,
                ),
                const SizedBox(height: 12),
                ...store.scenes.map(
                  (scene) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SceneCard(
                      title: scene.name,
                      emoji: scene.emoji,
                      subtitle: store.deviceSummary(scene),
                      active: scene.active,
                      onActivate: () {
                        store.activateScene(scene.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Scene "${scene.name}" activated'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        Text('Scenes', style: AppTextStyles.heading28),
        const HeaderActionButton(icon: Icons.notifications),
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.active,
    required this.onActivate,
  });

  final String title;
  final String emoji;
  final String subtitle;
  final bool active;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
            onPressed: onActivate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(84, 38),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: active
                  ? AppColors.successForeground
                  : AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(active ? 'Active' : 'Activate'),
          ),
        ],
      ),
    );
  }
}
