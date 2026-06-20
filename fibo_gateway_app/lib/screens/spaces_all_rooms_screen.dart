import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';
import '../widgets/room_image_cover.dart';
import 'space_models.dart';

class SpacesAllRoomsScreen extends StatelessWidget {
  const SpacesAllRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    itemCount: store.rooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (_, index) {
                      final room = store.rooms[index];
                      return _RoomCard(
                        room: room,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed('/spaces/room-detail', arguments: room.id),
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
              child: Text('All Rooms', style: SpaceTextStyles.navTitle),
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

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final SpaceRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 244,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SpaceColors.stroke, width: 1),
          color: SpaceColors.bgSurface,
        ),
        child: Column(
          children: [
            Expanded(
              child: RoomImageCover(
                imageUrl: room.imageUrl,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                backgroundGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x55314252), Color(0x33314252)],
                ),
                overlayGradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x08000000), Color(0x4A000000)],
                ),
                placeholderIconColor: SpaceColors.textMuted,
                placeholderIconSize: 30,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 86),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: SpaceTextStyles.pillTitle.copyWith(
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Text(room.onSummary, style: SpaceTextStyles.cardMeta),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: room.devices.take(5).map((device) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _DeviceRoundIcon(
                          icon: device.icon,
                          active: device.isOn,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceRoundIcon extends StatelessWidget {
  const _DeviceRoundIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? SpaceColors.textPrimary : Colors.transparent,
        border: Border.all(
          color: active ? SpaceColors.textPrimary : SpaceColors.stroke,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? SpaceColors.bgBase : SpaceColors.textMuted,
      ),
    );
  }
}
