import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';
import '../widgets/room_image_cover.dart';
import '../widgets/space_bottom_bar.dart';
import 'space_models.dart';

class SpacesOverviewScreen extends StatelessWidget {
  const SpacesOverviewScreen({
    super.key,
    this.showBottomBar = true,
    this.embedded = false,
  });

  /// The persistent tab shell renders the bottom bar itself, so embedded
  /// instances suppress their own.
  final bool showBottomBar;

  /// When true, returns just the Rooms + Devices content column (no Scaffold,
  /// top bar, scroll view or "View All") so it can be inlined into the Home
  /// dashboard.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final content = _content(context, store);
        if (embedded) return content;
        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: content,
                  ),
                ),
                if (showBottomBar)
                  const SpaceBottomBar(active: SpaceTab.spaces),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, SpaceMockStore store) {
    final categories = _buildDeviceCategories(store);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Rooms',
          count: store.rooms.length,
          actionLabel: embedded ? null : 'View All',
          onAction: embedded
              ? null
              : () => Navigator.of(context).pushNamed('/spaces/rooms'),
          actionIcon: Icons.add,
          onActionIcon: () =>
              Navigator.of(context).pushNamed('/spaces/new-room'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 254,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.rooms.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, index) => _RoomCard(
              room: store.rooms[index],
              onTap: () => Navigator.of(context).pushNamed(
                '/spaces/room-detail',
                arguments: store.rooms[index].id,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SectionHeader(
          title: 'Devices',
          count: store.totalDevices,
          actionLabel: embedded ? null : 'View All',
          onAction: embedded
              ? null
              : () => Navigator.of(context).pushNamed('/spaces/devices'),
          actionIcon: Icons.add,
          onActionIcon: () =>
              Navigator.of(context).pushNamed('/pairing/start'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, index) {
              final category = categories[index];
              return _DeviceCategoryCard(
                item: category,
                onTap: () {
                  // "View All" → every device; a category card → the All
                  // Devices list filtered to that group.
                  Navigator.of(context).pushNamed(
                    '/spaces/devices',
                    arguments: category.name == 'View All'
                        ? null
                        : category.name,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<_DeviceCategorySummary> _buildDeviceCategories(SpaceMockStore store) {
    // Group live devices by a category derived from their shadow profile.
    final byCat = <String, _DeviceCategorySummary>{};
    for (final device in store.allDevices) {
      final cat = _categoryFor(device);
      final existing = byCat[cat.$1];
      byCat[cat.$1] = _DeviceCategorySummary(
        name: cat.$1,
        icon: cat.$2,
        count: (existing?.count ?? 0) + 1,
      );
    }
    final cats = byCat.values.toList()
      ..sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
    return [
      ...cats.take(3),
      const _DeviceCategorySummary(
        name: 'View All',
        count: null,
        icon: Icons.grid_view_rounded,
        outlined: true,
      ),
    ];
  }

  (String, IconData) _categoryFor(SpaceDeviceState d) {
    final c = spaceDeviceCategory(d);
    return (c.label, c.icon);
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
          const SizedBox(width: 44),
          const Expanded(
            child: Center(
              child: Text('My Spaces', style: SpaceTextStyles.navTitle),
            ),
          ),
          const _TopMenuButton(),
        ],
      ),
    );
  }
}

class _TopMenuButton extends StatelessWidget {
  const _TopMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: SpaceColors.bgElevated,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'new-room') {
          Navigator.of(context).pushNamed('/spaces/new-room');
          return;
        }
        if (value == 'new-device') {
          Navigator.of(context).pushNamed('/pairing/start');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'new-room',
          child: Text(
            'New Room',
            style: SpaceTextStyles.pillTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'new-device',
          child: Text(
            'New Device',
            style: SpaceTextStyles.pillTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.menu, color: SpaceColors.textPrimary, size: 22),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.onActionIcon,
  });

  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final VoidCallback? onActionIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: SpaceTextStyles.sectionTitle),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('($count)', style: SpaceTextStyles.sectionCount),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                actionLabel!,
                style: SpaceTextStyles.cardMeta.copyWith(
                  color: SpaceColors.textPrimary,
                ),
              ),
            ),
          ),
        if (actionIcon != null && onActionIcon != null) ...[
          if (actionLabel != null && onAction != null)
            const SizedBox(width: 12),
          _SectionActionIconButton(icon: actionIcon!, onTap: onActionIcon!),
        ],
      ],
    );
  }
}

class _SectionActionIconButton extends StatelessWidget {
  const _SectionActionIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: SpaceColors.bgSurface,
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Icon(icon, color: SpaceColors.textPrimary, size: 18),
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
    final devices = room.devices.take(4).toList(growable: false);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 144,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: SpaceColors.bgSurface,
        ),
        child: Column(
          children: [
            Expanded(
              child: RoomImageCover(
                imageUrl: room.imageUrl,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                backgroundGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x44314252), Color(0x22314252)],
                ),
                overlayGradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x10000000), Color(0x48000000)],
                ),
                placeholderIconColor: SpaceColors.textMuted,
                placeholderIconSize: 28,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: SpaceTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(room.onSummary, style: SpaceTextStyles.cardMeta),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final entry in devices.asMap().entries) ...[
                        _DeviceIconChip(device: entry.value),
                        if (entry.key != devices.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
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

class _DeviceIconChip extends StatelessWidget {
  const _DeviceIconChip({required this.device});

  final SpaceDeviceState device;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: device.isOn ? SpaceColors.textPrimary : Colors.transparent,
        border: Border.all(
          color: device.isOn ? SpaceColors.textPrimary : SpaceColors.stroke,
        ),
      ),
      child: Icon(
        device.icon,
        size: 13,
        color: device.isOn ? SpaceColors.bgBase : SpaceColors.textMuted,
      ),
    );
  }
}

class _DeviceCategoryCard extends StatelessWidget {
  const _DeviceCategoryCard({required this.item, this.onTap});

  final _DeviceCategorySummary item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 98,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: item.outlined
            ? Border.all(color: SpaceColors.stroke, width: 2)
            : null,
        gradient: item.outlined
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [SpaceColors.bgElevated, SpaceColors.bgSurface],
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: SpaceColors.textPrimary, size: 26),
          const SizedBox(height: 8),
          Text(
            item.name == 'Air Conditioner' ? 'AC' : item.name,
            style: SpaceTextStyles.pillTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.count != null) ...[
            const SizedBox(height: 2),
            Text('x${item.count} Devices', style: SpaceTextStyles.pillMeta),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
    );
  }
}

class _DeviceCategorySummary {
  const _DeviceCategorySummary({
    required this.name,
    required this.count,
    required this.icon,
    this.outlined = false,
  });

  final String name;
  final int? count;
  final IconData icon;
  final bool outlined;
}
