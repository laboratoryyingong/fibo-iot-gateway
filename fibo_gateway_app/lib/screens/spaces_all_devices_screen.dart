import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';
import 'space_device_types.dart';
import 'space_models.dart';

class SpacesAllDevicesScreen extends StatelessWidget {
  const SpacesAllDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    // Optional category filter passed from the Devices section cards (e.g.
    // "Lights", "Sensors"). Null = show every device.
    final categoryFilter = ModalRoute.of(context)?.settings.arguments as String?;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        // Flatten the real rooms into (room, device) pairs so each card maps to
        // an actual device and can navigate to its control screen.
        final entries = <({SpaceRoom room, SpaceDeviceState device})>[
          for (final room in store.rooms)
            for (final device in room.devices)
              if (categoryFilter == null ||
                  spaceDeviceCategory(device).label == categoryFilter)
                (room: room, device: device),
        ];

        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(count: entries.length, title: categoryFilter),
                Expanded(
                  child: entries.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: entries.length,
                          itemBuilder: (_, index) {
                            final entry = entries[index];
                            return _DeviceCard(
                              device: entry.device,
                              onTap: () => Navigator.of(context).pushNamed(
                                '/spaces/device-control',
                                arguments: SpaceDeviceControlArgs(
                                  type: entry.device.controlType,
                                  roomId: entry.room.id,
                                  deviceId: entry.device.id,
                                  deviceName: entry.device.name,
                                ),
                              ),
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.count, this.title});

  final int count;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final base = title ?? 'All Devices';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                count == 0 ? base : '$base · $count',
                style: SpaceTextStyles.navTitle,
              ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices_other_outlined,
              color: SpaceColors.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No devices yet',
              style: SpaceTextStyles.pillTitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onTap});

  final SpaceDeviceState device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = device.valueLabel ?? (device.isOn ? 'On' : 'Off');
    final accent = device.isOn
        ? SpaceColors.accentStart
        : SpaceColors.textPrimary;
    return Opacity(
      opacity: device.online ? 1 : 0.5,
      child: InkWell(
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
              Icon(device.icon, color: accent, size: 28),
              const SizedBox(height: 10),
              Text(
                device.name,
                style: SpaceTextStyles.pillTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: SpaceTextStyles.pillMeta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
