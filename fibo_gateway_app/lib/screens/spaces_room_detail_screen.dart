import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'space_device_types.dart';
import 'space_models.dart';

class SpacesRoomDetailScreen extends StatelessWidget {
  const SpacesRoomDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final argument = ModalRoute.of(context)?.settings.arguments;
        final roomId = _resolveRoomId(argument, store);
        final room = roomId == null ? null : store.findRoomById(roomId);

        if (room == null) {
          return Scaffold(
            backgroundColor: SpaceColors.bgBase,
            body: const SafeArea(
              child: Center(
                child: Text('Room not found', style: SpaceTextStyles.pillTitle),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(title: room.name),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: room.devices.length,
                    itemBuilder: (_, index) {
                      final device = room.devices[index];
                      return _DeviceStatusCard(
                        device: device,
                        onToggle: () => store.toggleDevicePower(
                          roomId: room.id,
                          deviceId: device.id,
                        ),
                        onTap: () => Navigator.of(context).pushNamed(
                          '/spaces/device-control',
                          arguments: SpaceDeviceControlArgs(
                            type: device.controlType,
                            roomId: room.id,
                            deviceId: device.id,
                            deviceName: device.name,
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

  String? _resolveRoomId(dynamic argument, SpaceMockStore store) {
    if (argument is String) return argument;
    if (argument is SpaceRoom) return argument.id;
    if (store.rooms.isEmpty) return null;
    return store.rooms.first.id;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

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
          Expanded(
            child: Center(child: Text(title, style: SpaceTextStyles.navTitle)),
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

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({
    required this.device,
    required this.onToggle,
    required this.onTap,
  });

  final SpaceDeviceState device;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = device.isOn
        ? SpaceColors.textPrimary
        : SpaceColors.bgBase;
    final textColor = device.isOn
        ? SpaceColors.bgBase
        : SpaceColors.textPrimary;
    final subtitleColor = device.isOn
        ? SpaceColors.bgSurface
        : SpaceColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: SpaceColors.stroke,
            width: device.isOn ? 0 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.isOn ? 'ON' : 'OFF',
                  style: SpaceTextStyles.pillTitle.copyWith(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
                _MiniSwitch(isOn: device.isOn, onTap: onToggle),
              ],
            ),
            const Spacer(),
            Center(child: Icon(device.icon, size: 28, color: textColor)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SpaceTextStyles.pillTitle.copyWith(
                  color: textColor,
                  fontSize: 20,
                ),
              ),
            ),
            if (device.valueLabel != null) ...[
              const SizedBox(height: 2),
              Center(
                child: Text(
                  device.valueLabel!,
                  style: SpaceTextStyles.cardMeta.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: isOn ? SpaceColors.accentStart : SpaceColors.bgElevated,
        ),
        child: Align(
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SpaceColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
