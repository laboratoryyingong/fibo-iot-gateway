import 'package:flutter/material.dart';

import 'package:fibo_core/theme/scenes_tokens.dart';
import 'package:fibo_core/theme/space_tokens.dart';
import '../widgets/space_bottom_bar.dart';
import 'scenes_models.dart';
import 'space_models.dart';

/// One row to render: real (Parse) scenes run via the backend; mock scenes
/// (dev fallback) open the authoring detail.
class _SceneRow {
  const _SceneRow({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.featured = false,
  });
  final String emoji;
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;
}

class ScenesListScreen extends StatelessWidget {
  const ScenesListScreen({
    super.key,
    this.showSpacesBottomTabs = false,
    this.embedded = false,
  });

  final bool showSpacesBottomTabs;

  /// When true, returns just the Scenes section (header + non-scrolling list)
  /// so it can be inlined into the Home dashboard.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final spaceStore = SpaceMockStore.instance;

    return AnimatedBuilder(
      animation: spaceStore,
      builder: (_, _) {
        final rows = _buildRows(context, spaceStore);
        final realMode = spaceStore.homeGraph != null;
        void onCreate() => Navigator.of(context)
            .pushNamed(realMode ? '/scenes/editor' : '/scenes/new');
        if (embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmbeddedScenesHeader(count: rows.length, onCreate: onCreate),
              const SizedBox(height: 14),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _SceneCard(row: rows[i]),
              ],
            ],
          );
        }
        return Scaffold(
          backgroundColor: ScenesColors.bgBase,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(onCreate: onCreate),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      ScenesLayout.horizontalPadding,
                      24,
                      ScenesLayout.horizontalPadding,
                      20,
                    ),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, index) => _SceneCard(row: rows[index]),
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

  List<_SceneRow> _buildRows(BuildContext context, SpaceMockStore spaceStore) {
    final graph = spaceStore.homeGraph;
    if (graph != null) {
      // Real scenes from Parse — tapping opens the editor (edit / run / delete).
      return [
        for (final s in graph.scenes)
          _SceneRow(
            emoji: s.icon,
            name: s.name,
            subtitle:
                '${s.actionCount} ${s.actionCount == 1 ? 'action' : 'actions'}',
            onTap: () => Navigator.of(context)
                .pushNamed('/scenes/editor', arguments: s.sceneId),
          ),
      ];
    }
    // Dev fallback: the mock authoring scenes.
    final store = ScenesMockStore.instance;
    return [
      for (final scene in store.scenes)
        _SceneRow(
          emoji: scene.emoji,
          name: scene.name,
          subtitle: store.deviceSummary(scene),
          featured: scene.featured,
          onTap: () => Navigator.of(context).pushNamed(
            '/scenes/detail',
            arguments: SceneDetailArgs(scene.id),
          ),
        ),
    ];
  }
}

/// Section header for the Scenes block when inlined on Home — matches the
/// Spaces section headers (title + count) and offers a create shortcut.
class _EmbeddedScenesHeader extends StatelessWidget {
  const _EmbeddedScenesHeader({required this.count, required this.onCreate});

  final int count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Scenes', style: SpaceTextStyles.sectionTitle),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('($count)', style: SpaceTextStyles.sectionCount),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onCreate,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: SpaceColors.bgSurface,
              border: Border.all(color: SpaceColors.stroke),
            ),
            child: const Icon(Icons.add, color: SpaceColors.textPrimary, size: 18),
          ),
        ),
      ],
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
  const _SceneCard({required this.row});

  final _SceneRow row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      onTap: row.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: row.featured ? Colors.white : ScenesColors.bgSurface,
          borderRadius: BorderRadius.circular(ScenesRadii.card),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Text(
                  row.emoji,
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
                    row.name,
                    style: row.featured
                        ? ScenesTextStyles.cardTitleDark
                        : ScenesTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(row.subtitle, style: ScenesTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
