import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../theme/scenes_tokens.dart';
import '../theme/space_tokens.dart';
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
                if (showSpacesBottomTabs) const _SpacesBottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpacesBottomBar extends StatelessWidget {
  const _SpacesBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: SpaceColors.bgBase,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        children: [
          const _BottomMenuButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _BottomTabPill(
                    label: 'Spaces',
                    selected: false,
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/spaces'),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _BottomTabPill(label: 'Scenes', selected: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.notifications,
            color: SpaceColors.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _BottomTabPill extends StatelessWidget {
  const _BottomTabPill({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tab = Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: selected
            ? const LinearGradient(
                colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
              )
            : null,
        color: selected ? null : SpaceColors.bgElevated,
        border: selected ? null : Border.all(color: SpaceColors.stroke),
      ),
      child: Center(
        child: Text(
          label,
          style: SpaceTextStyles.pillTitle.copyWith(
            color: selected ? SpaceColors.textPrimary : SpaceColors.textMuted,
          ),
        ),
      ),
    );

    if (onTap == null) return tab;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: tab,
    );
  }
}

class _BottomMenuButton extends StatelessWidget {
  const _BottomMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: SpaceColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (selected) async {
        if (selected == 'logout') {
          final user = await ParseUser.currentUser() as ParseUser?;
          await user?.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout', style: SpaceTextStyles.pillTitle),
        ),
      ],
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Icon(Icons.home_filled, color: SpaceColors.textMuted, size: 22),
      ),
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
            const SizedBox(width: 68),
            const Expanded(
              child: Center(
                child: Text('Scenes', style: ScenesTextStyles.navTitle),
              ),
            ),
            _CreateButton(onTap: onCreate),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 68,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ScenesColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '+ New',
          style: ScenesTextStyles.buttonSmall.copyWith(
            color: ScenesColors.accentStart,
          ),
        ),
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
