import 'package:flutter/material.dart';

import 'package:fibo_core/theme/scenes_tokens.dart';
import 'scenes_models.dart';

class ScenesSelectDeviceScreen extends StatefulWidget {
  const ScenesSelectDeviceScreen({super.key});

  @override
  State<ScenesSelectDeviceScreen> createState() =>
      _ScenesSelectDeviceScreenState();
}

class _ScenesSelectDeviceScreenState extends State<ScenesSelectDeviceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDeviceId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is SceneSelectDeviceArgs ? rawArgs : null;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = store.devices.where((device) {
      if (query.isEmpty) return true;
      return device.name.toLowerCase().contains(query) ||
          device.room.toLowerCase().contains(query);
    }).toList();

    final grouped = <String, List<SceneDevice>>{};
    for (final device in filtered) {
      grouped.putIfAbsent(device.room, () => []).add(device);
    }

    final rooms = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: ScenesColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 12, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ScenesColors.bgSurface,
                  borderRadius: BorderRadius.circular(ScenesRadii.card),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: ScenesColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: ScenesTextStyles.body,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search devices...',
                          hintStyle: ScenesTextStyles.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(23, 12, 24, 16),
                children: [
                  for (final room in rooms) ...[
                    Text(room, style: ScenesTextStyles.caption),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ScenesRadii.card),
                        gradient: ScenesGradients.surface,
                      ),
                      child: Column(
                        children: [
                          for (final entry
                              in grouped[room]!.asMap().entries) ...[
                            _DeviceRow(
                              device: entry.value,
                              selected: _selectedDeviceId == entry.value.id,
                              onTap: () {
                                setState(() {
                                  _selectedDeviceId = entry.value.id;
                                });
                              },
                            ),
                            if (entry.key != grouped[room]!.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0x22314252),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 12, 24, 24),
              child: _ConfirmButton(
                enabled: _selectedDeviceId != null,
                label:
                    'Confirm Selection (${_selectedDeviceId == null ? 0 : 1})',
                onTap: () {
                  if (args == null || _selectedDeviceId == null) {
                    Navigator.of(context).pop();
                    return;
                  }
                  store.addStepFromTemplate(
                    sceneId: args.sceneId,
                    type: args.type,
                    templateId: args.templateId,
                    deviceId: _selectedDeviceId,
                  );
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
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
        ScenesLayout.navTopPadding,
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
                child: Text('Select Device', style: ScenesTextStyles.navTitle),
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

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final SceneDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                device.icon,
                color: ScenesColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: ScenesTextStyles.buttonSmall),
                  const SizedBox(height: 2),
                  Text(device.status, style: ScenesTextStyles.caption),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ScenesColors.accentStart : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? ScenesColors.accentStart
                      : ScenesColors.textMuted,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: ScenesColors.textPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScenesRadii.card),
            gradient: ScenesGradients.primaryButton,
          ),
          alignment: Alignment.center,
          child: Text(label, style: ScenesTextStyles.button),
        ),
      ),
    );
  }
}
