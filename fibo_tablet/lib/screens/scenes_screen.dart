import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';

/// The Scenes pane: lists the home's scenes and runs one with a tap.
class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  final _running = <String>{};

  Future<void> _run(HomeScene scene) async {
    if (_running.contains(scene.sceneId)) return;
    setState(() => _running.add(scene.sceneId));
    String? error;
    try {
      await widget.controller.runScene(scene.sceneId);
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() => _running.remove(scene.sceneId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SpaceColors.bgElevated,
        content: Text(
          error == null ? '${scene.name} started' : 'Couldn\'t run ${scene.name}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: SpaceColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scenes', style: SpaceTextStyles.sectionTitle),
              const SizedBox(height: 20),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _body() {
    final controller = widget.controller;
    if (controller.state == HomeLoadState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: SpaceColors.accentStart),
      );
    }
    final scenes = controller.scenes;
    if (scenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                size: 52, color: SpaceColors.textMuted),
            const SizedBox(height: 16),
            Text('No scenes yet.', style: SpaceTextStyles.cardMeta),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final s in scenes)
            _SceneCard(
              scene: s,
              running: _running.contains(s.sceneId),
              onTap: () => _run(s),
            ),
        ],
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.running,
    required this.onTap,
  });

  final HomeScene scene;
  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SpaceColors.bgElevated, SpaceColors.bgSurface],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Text(scene.icon,
                    style: const TextStyle(fontSize: 34, height: 1.2)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SpaceTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scene.actionCount} ${scene.actionCount == 1 ? 'action' : 'actions'}',
                    style: SpaceTextStyles.pillMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (running)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: SpaceColors.accentStart,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SpaceColors.bgBase,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: SpaceColors.accentStart, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}
