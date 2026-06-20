import 'package:flutter/material.dart';

import 'package:fibo_core/theme/scenes_tokens.dart';
import 'scenes_models.dart';

class ScenesNewScreen extends StatefulWidget {
  const ScenesNewScreen({super.key});

  @override
  State<ScenesNewScreen> createState() => _ScenesNewScreenState();
}

class _ScenesNewScreenState extends State<ScenesNewScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedDeviceIds = <String>[];
  late String _emoji;

  @override
  void initState() {
    super.initState();
    final store = ScenesMockStore.instance;
    _emoji = store.emojis.first;
    _selectedDeviceIds.addAll(store.devices.take(3).map((device) => device.id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _cycleEmoji() {
    final store = ScenesMockStore.instance;
    final current = store.emojis.indexOf(_emoji);
    final next = (current + 1) % store.emojis.length;
    setState(() {
      _emoji = store.emojis[next];
    });
  }

  void _addDevice() {
    final store = ScenesMockStore.instance;
    for (final device in store.devices) {
      if (!_selectedDeviceIds.contains(device.id)) {
        setState(() {
          _selectedDeviceIds.add(device.id);
        });
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All mock devices are already selected.')),
    );
  }

  void _removeDevice(String deviceId) {
    setState(() {
      _selectedDeviceIds.remove(deviceId);
    });
  }

  void _submit() {
    final store = ScenesMockStore.instance;
    final sceneId = store.createScene(
      name: _nameController.text,
      emoji: _emoji,
      deviceIds: _selectedDeviceIds,
    );
    Navigator.of(context).pushReplacementNamed(
      '/scenes/detail',
      arguments: SceneDetailArgs(sceneId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ScenesMockStore.instance;
    final deviceById = {for (final device in store.devices) device.id: device};
    final selectedDevices = _selectedDeviceIds
        .map((id) => deviceById[id])
        .whereType<SceneDevice>()
        .toList(growable: false);

    return Scaffold(
      backgroundColor: ScenesColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ScenesLayout.horizontalPadding,
                  24,
                  ScenesLayout.horizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Name', style: ScenesTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _cycleEmoji,
                          child: Container(
                            width: 104,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            decoration: BoxDecoration(
                              color: ScenesColors.bgField,
                              borderRadius: BorderRadius.circular(
                                ScenesRadii.card,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Emoji',
                                  style: ScenesTextStyles.mutedBody,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _emoji,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: ScenesColors.bgField,
                              borderRadius: BorderRadius.circular(
                                ScenesRadii.card,
                              ),
                            ),
                            child: TextField(
                              controller: _nameController,
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
                    ),
                    const SizedBox(height: 28),
                    const Text('Devices', style: ScenesTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    const Text(
                      'Select devices to include in this scene',
                      style: ScenesTextStyles.mutedBody,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _AddChip(onTap: _addDevice),
                        for (final device in selectedDevices)
                          _DeviceSummaryChip(
                            device: device,
                            onRemove: () => _removeDevice(device.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ScenesLayout.horizontalPadding,
                8,
                ScenesLayout.horizontalPadding,
                24,
              ),
              child: _GradientButton(
                label: 'Submit',
                onTap: _submit,
                gradient: ScenesGradients.primaryButton,
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
                child: Text('New Scene', style: ScenesTextStyles.navTitle),
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

class _DeviceSummaryChip extends StatelessWidget {
  const _DeviceSummaryChip({required this.device, required this.onRemove});

  final SceneDevice device;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 114,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: 94,
            height: 114,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: ScenesGradients.surface,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 66,
                  child: Align(
                    alignment: const Alignment(0, 0.9),
                    child: Icon(
                      device.icon,
                      color: const Color(0xFF1E2B34),
                      size: 34,
                    ),
                  ),
                ),
                Container(
                  height: 40,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ScenesTextStyles.caption.copyWith(
                      color: ScenesColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B57),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove,
                  size: 18,
                  color: ScenesColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 94,
        height: 114,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: ScenesGradients.surface,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 66,
              child: Align(
                alignment: const Alignment(0, 0.9),
                child: const Icon(
                  Icons.add,
                  size: 30,
                  color: ScenesColors.textPrimary,
                ),
              ),
            ),
            Container(
              height: 40,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Text(
                'Add',
                style: ScenesTextStyles.caption.copyWith(
                  color: ScenesColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScenesRadii.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ScenesRadii.card),
          gradient: gradient,
        ),
        alignment: Alignment.center,
        child: Text(label, style: ScenesTextStyles.button),
      ),
    );
  }
}
