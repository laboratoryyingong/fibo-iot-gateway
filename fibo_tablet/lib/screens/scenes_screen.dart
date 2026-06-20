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
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title matching the Home room titles so the first tile
              // row lines up across the Home↔Scenes swipe.
              Text('Scenes', style: SpaceTextStyles.cardTitle),
              const SizedBox(height: 14),
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
    // Same fixed-height grid as the Home device tiles.
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 28),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 308,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: scenes.length,
      itemBuilder: (_, i) => _SceneCard(
        scene: scenes[i],
        running: _running.contains(scenes[i].sceneId),
        onTap: () => _run(scenes[i]),
      ),
    );
  }
}

/// Scene tile matching the Home device tiles: a vertical gradient card with a
/// centered hero icon, name and action count, plus a Run button.
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SpaceColors.bgElevated, SpaceColors.bgSurface],
        ),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SpaceColors.bgBase,
              ),
              child: Text(scene.icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            scene.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SpaceTextStyles.pillTitle,
          ),
          const SizedBox(height: 2),
          Text(
            '${scene.actionCount} ${scene.actionCount == 1 ? 'action' : 'actions'}',
            textAlign: TextAlign.center,
            style: SpaceTextStyles.pillMeta,
          ),
          const SizedBox(height: 14),
          _RunButton(running: running, onTap: onTap),
        ],
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.running, required this.onTap});

  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: running ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: SpaceColors.accentStart,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: running
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Run',
                      style: SpaceTextStyles.pillTitle
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
