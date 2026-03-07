import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'space_models.dart';

class SpacesNewRoomScreen extends StatefulWidget {
  const SpacesNewRoomScreen({super.key});

  @override
  State<SpacesNewRoomScreen> createState() => _SpacesNewRoomScreenState();
}

class _SpacesNewRoomScreenState extends State<SpacesNewRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedDeviceTemplateIds = {'tpl-ceiling'};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    final allDeviceTemplates = store.deviceTemplates.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  Text(
                    'Name',
                    style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SpaceColors.stroke),
                      color: SpaceColors.bgBase,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _nameController,
                        style: SpaceTextStyles.pillTitle.copyWith(
                          color: SpaceColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Room Name',
                          hintStyle: SpaceTextStyles.cardMeta,
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Wallpaper',
                    style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select wallpaper for your room',
                    style: SpaceTextStyles.sectionCount,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wallpaper picker will be connected next.',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: SpaceColors.bgElevated,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: SpaceColors.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Add Image',
                            style: SpaceTextStyles.pillTitle.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Devices',
                    style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select devices to include in this room',
                    style: SpaceTextStyles.sectionCount,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AddDeviceChip(
                        onTap: () =>
                            _showDevicePicker(context, allDeviceTemplates),
                      ),
                      ..._selectedDeviceTemplateIds.map(
                        (templateId) => _SelectedDeviceChip(
                          name: _templateNameById(
                            allDeviceTemplates,
                            templateId,
                          ),
                          onRemove: () => setState(
                            () => _selectedDeviceTemplateIds.remove(templateId),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final roomName = _nameController.text.trim();
                  if (roomName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter room name.')),
                    );
                    return;
                  }
                  final room = store.addRoom(
                    name: roomName,
                    templateIds: _selectedDeviceTemplateIds.toList(),
                  );
                  if (room == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add at least one device.'),
                      ),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamed('/spaces/room-detail', arguments: room.id);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Add New Room',
                      style: SpaceTextStyles.pillTitle.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDevicePicker(
    BuildContext context,
    List<SpaceDeviceTemplate> allDeviceTemplates,
  ) async {
    final available = allDeviceTemplates
        .where((template) => !_selectedDeviceTemplateIds.contains(template.id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All devices have been selected.')),
      );
      return;
    }

    final selectedTemplateId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: SpaceColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: available.length,
            separatorBuilder: (_, _) =>
                const Divider(color: SpaceColors.stroke, height: 1),
            itemBuilder: (_, index) {
              final template = available[index];
              return ListTile(
                title: Text(
                  template.name,
                  style: SpaceTextStyles.pillTitle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.add, color: SpaceColors.textPrimary),
                onTap: () => Navigator.of(context).pop(template.id),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selectedTemplateId == null) return;
    setState(() => _selectedDeviceTemplateIds.add(selectedTemplateId));
  }

  String _templateNameById(
    List<SpaceDeviceTemplate> templates,
    String templateId,
  ) {
    for (final item in templates) {
      if (item.id == templateId) return item.name;
    }
    return templateId;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Center(
              child: Text('New Room', style: SpaceTextStyles.navTitle),
            ),
          ),
          _IconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).popUntil(
              (route) => route.settings.name == '/spaces' || route.isFirst,
            ),
          ),
        ],
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
        width: 40,
        height: 40,
        child: Icon(icon, color: SpaceColors.textPrimary, size: 20),
      ),
    );
  }
}

class _AddDeviceChip extends StatelessWidget {
  const _AddDeviceChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 98,
        height: 98,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SpaceColors.stroke),
          color: SpaceColors.bgBase,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: SpaceColors.textPrimary),
            const SizedBox(height: 8),
            Text(
              'Add',
              style: SpaceTextStyles.pillTitle.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDeviceChip extends StatelessWidget {
  const _SelectedDeviceChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: SpaceColors.bgElevated,
            border: Border.all(color: SpaceColors.stroke),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: SpaceTextStyles.pillTitle.copyWith(fontSize: 14),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFF85365),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                size: 18,
                color: SpaceColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
