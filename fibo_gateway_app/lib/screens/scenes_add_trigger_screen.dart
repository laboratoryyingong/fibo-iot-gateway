import 'package:flutter/material.dart';

import 'package:fibo_core/theme/scenes_tokens.dart';
import 'scenes_models.dart';

class ScenesAddTriggerScreen extends StatelessWidget {
  const ScenesAddTriggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final sceneId = rawArgs is SceneFlowArgs ? rawArgs.sceneId : null;

    final templates = store.triggerTemplates.toList()
      ..sort((a, b) {
        const order = <String, int>{
          'trigger-device-state': 0,
          'trigger-schedule': 1,
          'trigger-location': 2,
          'trigger-manual': 3,
        };
        return (order[a.id] ?? 99).compareTo(order[b.id] ?? 99);
      });

    return Scaffold(
      backgroundColor: ScenesColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Trigger Type',
                      style: ScenesTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    ...templates.map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TypeCard(
                          template: template,
                          onTap: () => _onSelectTemplate(
                            context,
                            store,
                            sceneId,
                            template,
                          ),
                        ),
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
  }

  void _onSelectTemplate(
    BuildContext context,
    ScenesMockStore store,
    String? sceneId,
    SceneTemplate template,
  ) {
    if (sceneId == null) {
      Navigator.of(context).pop();
      return;
    }
    if (template.requiresDevice) {
      Navigator.of(context).pushNamed(
        '/scenes/select-device',
        arguments: SceneSelectDeviceArgs(
          sceneId: sceneId,
          type: SceneFlowType.trigger,
          templateId: template.id,
        ),
      );
      return;
    }
    store.addStepFromTemplate(
      sceneId: sceneId,
      type: SceneFlowType.trigger,
      templateId: template.id,
    );
    Navigator.of(context).pop();
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
                child: Text('Add Trigger', style: ScenesTextStyles.navTitle),
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.template, required this.onTap});

  final SceneTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScenesRadii.panel),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: ScenesLayout.flowCardHeight,
        ),
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
              child: Icon(
                template.icon,
                color: ScenesColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title, style: ScenesTextStyles.buttonSmall),
                  const SizedBox(height: 2),
                  Text(template.description, style: ScenesTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
