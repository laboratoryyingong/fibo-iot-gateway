import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'home_profile_models.dart';

class HomeProfileHomeScreen extends StatelessWidget {
  const HomeProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeProfileMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final selected = store.selectedProfile;
        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  profile: selected,
                  onAvatarTap: () => Navigator.of(
                    context,
                  ).pushNamed('/home/profile/menu', arguments: selected.id),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileSelector(
                          profiles: store.profiles,
                          selectedId: store.selectedProfileId,
                          onTap: store.selectProfile,
                        ),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Scenes',
                          count: selected.scenes.length,
                          onViewAll: () =>
                              Navigator.of(context).pushNamed('/home/scenes'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 94,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: selected.scenes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, index) => _SceneChip(
                              scene: selected.scenes[index],
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed('/home/scenes'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _SectionHeader(
                          title: 'Spaces',
                          count: selected.spaces.length,
                          onViewAll: () =>
                              Navigator.of(context).pushNamed('/spaces'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 330,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: selected.spaces.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (_, index) {
                              final space = selected.spaces[index];
                              return _SpaceCard(
                                space: space,
                                location: selected.location,
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed('/spaces/room-detail'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _BottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onAvatarTap});

  final HomeProfileItem profile;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 112, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Mornin’ ${profile.ownerFirstName}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 32),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onAvatarTap,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
              ),
              child: Container(
                width: 80,
                height: 88,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC6E7E90), Color(0xAA4E5E70)],
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: SpaceColors.bgSurface,
                    child: Text(
                      _initials(profile.ownerFullName),
                      style: SpaceTextStyles.pillTitle.copyWith(
                        color: SpaceColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'H';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ProfileSelector extends StatelessWidget {
  const _ProfileSelector({
    required this.profiles,
    required this.selectedId,
    required this.onTap,
  });

  final List<HomeProfileItem> profiles;
  final String selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final profile = profiles[index];
          final selected = selectedId == profile.id;
          return InkWell(
            onTap: () => onTap(profile.id),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: selected
                    ? const LinearGradient(
                        colors: [
                          SpaceColors.accentStart,
                          SpaceColors.accentEnd,
                        ],
                      )
                    : null,
                color: selected ? null : SpaceColors.bgElevated,
                border: selected ? null : Border.all(color: SpaceColors.stroke),
              ),
              alignment: Alignment.center,
              child: Text(
                profile.name,
                style: SpaceTextStyles.pillTitle.copyWith(
                  color: selected
                      ? SpaceColors.textPrimary
                      : SpaceColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onViewAll,
  });

  final String title;
  final int count;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: SpaceTextStyles.sectionTitle),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text('($count)', style: SpaceTextStyles.sectionCount),
        ),
        const Spacer(),
        InkWell(
          onTap: onViewAll,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Text(
              'View All',
              style: SpaceTextStyles.cardMeta.copyWith(
                color: SpaceColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.scene, required this.onTap});

  final HomeProfileScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scene.active ? Colors.white : SpaceColors.bgElevated,
                border: Border.all(
                  color: scene.active ? Colors.white : SpaceColors.bgSurface,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(scene.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scene.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: SpaceTextStyles.pillTitle.copyWith(
                color: scene.active
                    ? SpaceColors.textPrimary
                    : SpaceColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.location,
    required this.onTap,
  });

  final HomeProfileSpace space;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 236,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3C4A), Color(0xFF22313C)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: SpaceColors.textMuted.withValues(alpha: 0.7),
                  size: 36,
                ),
              ),
            ),
            Container(
              height: 122,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xBB25313D),
                borderRadius: const BorderRadius.vertical(
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
                          space.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SpaceTextStyles.pillTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${space.onDevices}/${space.totalDevices} is on',
                        style: SpaceTextStyles.cardMeta.copyWith(
                          color: SpaceColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(location, style: SpaceTextStyles.pillMeta),
                  const Spacer(),
                  Row(
                    children: [
                      for (var i = 0; i < space.icons.length && i < 4; i++) ...[
                        _DeviceIconDot(
                          icon: space.icons[i],
                          active: i < space.onDevices,
                        ),
                        if (i != space.icons.length - 1 && i < 3)
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

class _DeviceIconDot extends StatelessWidget {
  const _DeviceIconDot({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? SpaceColors.textPrimary : Colors.transparent,
        border: Border.all(
          color: active ? SpaceColors.textPrimary : SpaceColors.stroke,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: active ? SpaceColors.bgBase : SpaceColors.textMuted,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: SpaceColors.bgBase,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_filled,
                    color: SpaceColors.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('Home', style: SpaceTextStyles.pillTitle),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _BottomIconButton(
            icon: Icons.bolt_outlined,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/home/scenes'),
          ),
          const SizedBox(width: 8),
          _BottomIconButton(
            icon: Icons.space_dashboard_outlined,
            onTap: () => Navigator.of(context).pushReplacementNamed('/spaces'),
          ),
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SpaceColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Icon(icon, color: SpaceColors.textMuted, size: 20),
      ),
    );
  }
}
