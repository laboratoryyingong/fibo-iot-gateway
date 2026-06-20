import 'package:flutter/material.dart';

import 'package:fibo_core/services/device_api_models.dart';
import 'package:fibo_core/theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Tap-to-activate scene grid, mirroring
/// design/fibo_claude_agent.pen › "51. Scenes".
class AssistantScenesCard extends StatelessWidget {
  const AssistantScenesCard({
    super.key,
    required this.scenes,
    required this.onRun,
  });

  final List<AgentScene> scenes;
  final void Function(AgentScene scene) onRun;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < scenes.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _SceneTile(scene: scenes[i], onRun: onRun)),
                const SizedBox(width: 12),
                if (i + 1 < scenes.length)
                  Expanded(child: _SceneTile(scene: scenes[i + 1], onRun: onRun))
                else
                  const Spacer(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({required this.scene, required this.onRun});

  final AgentScene scene;
  final void Function(AgentScene scene) onRun;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(scene.name);
    final summary = scene.description.isNotEmpty
        ? scene.description
        : '${scene.steps.length} ${scene.steps.length == 1 ? "action" : "actions"}';

    return GestureDetector(
      onTap: () {
        onRun(scene);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activating ${scene.name}…'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: AgentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: kCardChipBg),
              child: Icon(visual.icon, size: 22, color: visual.fg),
            ),
            const SizedBox(height: 10),
            Text(scene.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CardText.title),
            const SizedBox(height: 4),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AgentColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SceneVisual _visualFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('sleep') || n.contains('night')) {
      return const _SceneVisual(Icons.bedtime_outlined, Color(0xFF818CF8));
    }
    if (n.contains('away') || n.contains('leave')) {
      return const _SceneVisual(Icons.lock_outline, Color(0xFF94A3B8));
    }
    if (n.contains('movie') || n.contains('cinema') || n.contains('film')) {
      return const _SceneVisual(Icons.movie_outlined, Color(0xFFA78BFA));
    }
    if (n.contains('morning') || n.contains('wake')) {
      return const _SceneVisual(Icons.wb_sunny_outlined, Color(0xFFFBBF24));
    }
    if (n.contains('home')) {
      return const _SceneVisual(Icons.home_outlined, Color(0xFFFB923C));
    }
    return const _SceneVisual(Icons.auto_awesome, AgentColors.accent);
  }
}

class _SceneVisual {
  const _SceneVisual(this.icon, this.fg);
  final IconData icon;
  final Color fg;
}
