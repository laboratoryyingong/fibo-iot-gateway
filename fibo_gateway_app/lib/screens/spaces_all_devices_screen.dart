import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'space_device_types.dart';
import 'space_models.dart';

class SpacesAllDevicesScreen extends StatelessWidget {
  const SpacesAllDevicesScreen({super.key});

  static const List<({String name, IconData icon})> _categoryOrder = [
    (name: 'Ceiling Light', icon: Icons.lightbulb_outline),
    (name: 'Air Conditioner', icon: Icons.ac_unit_outlined),
    (name: 'Climate', icon: Icons.thermostat_outlined),
    (name: 'Fan', icon: Icons.mode_fan_off_outlined),
    (name: 'Bulb', icon: Icons.tungsten_outlined),
    (name: 'Air Purifier', icon: Icons.air_outlined),
    (name: 'Television', icon: Icons.tv_outlined),
    (name: 'Washing Machine', icon: Icons.local_laundry_service_outlined),
    (name: 'Speakers', icon: Icons.speaker_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final nameCounts = store.deviceNameCounts;
        final categories = _categoryOrder.map((item) {
          final sourceName = _sourceName(item.name);
          return _DeviceCategory(
            name: item.name,
            sourceName: sourceName,
            count: nameCounts[sourceName] ?? 0,
            icon: item.icon,
            type: mapDeviceNameToControlType(item.name),
          );
        }).toList();

        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (_, index) {
                      final category = categories[index];
                      return _CategoryCard(
                        category: category,
                        onTap: () {
                          final target = store.findFirstDeviceByName(
                            category.sourceName,
                          );
                          Navigator.of(context).pushNamed(
                            '/spaces/device-control',
                            arguments: SpaceDeviceControlArgs(
                              type: category.type,
                              roomId: target?.room.id,
                              deviceId: target?.device.id,
                              deviceName: category.name,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sourceName(String displayName) {
    if (displayName == 'Air Purifier') return 'Purifier';
    return displayName;
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
              child: Text('All Devices', style: SpaceTextStyles.navTitle),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _DeviceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SpaceColors.bgElevated, SpaceColors.bgSurface],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: SpaceColors.textPrimary, size: 28),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: SpaceTextStyles.pillTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('x${category.count} Devices', style: SpaceTextStyles.pillMeta),
          ],
        ),
      ),
    );
  }
}

class _DeviceCategory {
  const _DeviceCategory({
    required this.name,
    required this.sourceName,
    required this.count,
    required this.icon,
    required this.type,
  });

  final String name;
  final String sourceName;
  final int count;
  final IconData icon;
  final SpaceDeviceControlType type;
}
