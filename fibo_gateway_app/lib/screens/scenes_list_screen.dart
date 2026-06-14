import 'package:flutter/material.dart';

import '../theme/scenes_tokens.dart';
import '../widgets/space_bottom_bar.dart';
import 'scenes_models.dart';

class ScenesListScreen extends StatelessWidget {
  const ScenesListScreen({super.key, this.showSpacesBottomTabs = false});

  final bool showSpacesBottomTabs;

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        return Scaffold(
          backgroundColor: ScenesColors.bgBase,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  onCreate: () =>
                      Navigator.of(context).pushNamed('/scenes/new'),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      ScenesLayout.horizontalPadding,
                      24,
                      ScenesLayout.horizontalPadding,
                      20,
                    ),
                    itemCount: store.scenes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      final scene = store.scenes[index];
                      return _SceneCard(
                        scene: scene,
                        subtitle: store.deviceSummary(scene),
                        onTap: () => Navigator.of(context).pushNamed(
                          '/scenes/detail',
                          arguments: SceneDetailArgs(scene.id),
                        ),
                      );
                    },
                  ),
                ),
                if (showSpacesBottomTabs)
                  const SpaceBottomBar(active: SpaceTab.scenes),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScenesLayout.horizontalPadding,
        0,
        ScenesLayout.horizontalPadding,
        0,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(width: 40),
            const Expanded(
              child: Center(
                child: Text('Scenes', style: ScenesTextStyles.navTitle),
              ),
            ),
            _SceneMenuButton(onCreate: onCreate),
          ],
        ),
      ),
    );
  }
}

class _SceneMenuButton extends StatelessWidget {
  const _SceneMenuButton({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: ScenesColors.bgElevated,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'create-scene') onCreate();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'create-scene',
          child: Text(
            'Create New Scene',
            style: ScenesTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ],
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.menu, color: ScenesColors.textPrimary, size: 22),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.subtitle,
    required this.onTap,
  });

  final SceneItem scene;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardDecoration = scene.featured
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ScenesRadii.card),
          )
        : BoxDecoration(
            color: ScenesColors.bgSurface,
            borderRadius: BorderRadius.circular(ScenesRadii.card),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Text(
                  scene.emoji,
                  style: const TextStyle(fontSize: 36, height: 1.2),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    style: scene.featured
                        ? ScenesTextStyles.cardTitleDark
                        : ScenesTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: ScenesTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
