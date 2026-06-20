import 'package:flutter/material.dart';

import 'package:fibo_core/theme/scenes_tokens.dart';
import 'scenes_models.dart';

class ScenesDetailScreen extends StatefulWidget {
  const ScenesDetailScreen({super.key});

  @override
  State<ScenesDetailScreen> createState() => _ScenesDetailScreenState();
}

class _ScenesDetailScreenState extends State<ScenesDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _emoji = '☀️';
  String? _loadedSceneId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncScene(SceneItem scene) {
    if (_loadedSceneId == scene.id) return;
    _loadedSceneId = scene.id;
    _nameController.text = scene.name;
    _emoji = scene.emoji;
  }

  void _cycleEmoji() {
    final store = ScenesMockStore.instance;
    final index = store.emojis.indexOf(_emoji);
    final next = (index + 1) % store.emojis.length;
    setState(() {
      _emoji = store.emojis[next];
    });
  }

  void _saveBasics(String sceneId) {
    ScenesMockStore.instance.saveSceneBasics(
      sceneId: sceneId,
      name: _nameController.text,
      emoji: _emoji,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final rawArgs = ModalRoute.of(context)?.settings.arguments;
        final sceneId = rawArgs is SceneDetailArgs
            ? rawArgs.sceneId
            : rawArgs is String
            ? rawArgs
            : store.scenes.firstOrNull?.id;

        if (sceneId == null) {
          return const Scaffold(
            body: Center(child: Text('No scene available.')),
          );
        }

        final scene = store.findScene(sceneId);
        if (scene == null) {
          return const Scaffold(body: Center(child: Text('Scene not found.')));
        }

        _syncScene(scene);

        return Scaffold(
          backgroundColor: ScenesColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: () {
                    _saveBasics(scene.id);
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      ScenesLayout.horizontalPadding,
                      24,
                      ScenesLayout.horizontalPadding,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: ScenesTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 16),
                        _NameSection(
                          controller: _nameController,
                          emoji: _emoji,
                          onTapEmoji: _cycleEmoji,
                        ),
                        const SizedBox(height: 16),
                        _DeleteButton(
                          onTap: () {
                            store.deleteScene(scene.id);
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(
                          text: 'Then (Actions)',
                          onAdd: () {
                            _saveBasics(scene.id);
                            Navigator.of(context).pushNamed(
                              '/scenes/add-action',
                              arguments: SceneFlowArgs(
                                sceneId: scene.id,
                                type: SceneFlowType.action,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ...scene.actions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FlowCard(step: action),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SectionLabel(
                          text: 'When (Triggers)',
                          onAdd: () {
                            _saveBasics(scene.id);
                            Navigator.of(context).pushNamed(
                              '/scenes/add-trigger',
                              arguments: SceneFlowArgs(
                                sceneId: scene.id,
                                type: SceneFlowType.trigger,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ...scene.triggers.map(
                          (trigger) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FlowCard(step: trigger),
                          ),
                        ),
                      ],
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
  const _Header({required this.onBack});

  final VoidCallback onBack;

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
            _IconButton(icon: Icons.arrow_back, onTap: onBack),
            const Expanded(
              child: Center(
                child: Text('Edit Scene', style: ScenesTextStyles.navTitle),
              ),
            ),
            const SizedBox(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, color: ScenesColors.textPrimary, size: 20),
      ),
    );
  }
}

class _NameSection extends StatelessWidget {
  const _NameSection({
    required this.controller,
    required this.emoji,
    required this.onTapEmoji,
  });

  final TextEditingController controller;
  final String emoji;
  final VoidCallback onTapEmoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTapEmoji,
          child: Container(
            width: 104,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: ScenesColors.bgField,
              borderRadius: BorderRadius.circular(ScenesRadii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emoji', style: ScenesTextStyles.mutedBody),
                const SizedBox(height: 8),
                Text(
                  emoji,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 40,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
            decoration: BoxDecoration(
              color: ScenesColors.bgField,
              borderRadius: BorderRadius.circular(ScenesRadii.card),
            ),
            child: TextField(
              controller: controller,
              style: ScenesTextStyles.mutedBody,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Scene Name',
                hintStyle: ScenesTextStyles.mutedBody,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ScenesRadii.card),
          gradient: ScenesGradients.deleteButton,
        ),
        child: const Text('Delete Scene', style: ScenesTextStyles.button),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.onAdd});

  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: ScenesTextStyles.sectionTitle),
        const Spacer(),
        InkWell(
          onTap: onAdd,
          child: const Text('Add', style: ScenesTextStyles.buttonSmall),
        ),
      ],
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.step});

  final SceneStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: ScenesLayout.flowCardHeight),
      padding: const EdgeInsets.fromLTRB(
        ScenesLayout.flowCardHorizontalPadding,
        ScenesLayout.flowCardVerticalPadding,
        ScenesLayout.flowCardHorizontalPadding,
        ScenesLayout.flowCardVerticalPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ScenesRadii.panel),
        gradient: ScenesGradients.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ScenesColors.bgElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(step.icon, color: ScenesColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: ScenesTextStyles.buttonSmall),
                const SizedBox(height: 2),
                Text(step.subtitle, style: ScenesTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
