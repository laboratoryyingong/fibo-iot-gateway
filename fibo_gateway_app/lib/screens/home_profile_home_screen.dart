import 'package:flutter/material.dart';

import '../services/gateway_linking_service.dart';
import '../theme/space_tokens.dart';
import '../widgets/room_image_cover.dart';
import '../widgets/space_bottom_bar.dart';
import 'home_profile_models.dart';

class HomeProfileHomeScreen extends StatefulWidget {
  const HomeProfileHomeScreen({super.key});

  @override
  State<HomeProfileHomeScreen> createState() => _HomeProfileHomeScreenState();
}

class _HomeProfileHomeScreenState extends State<HomeProfileHomeScreen> {
  GatewayProfile? _selectedGateway;
  bool _loadingGateway = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedGateway();
  }

  Future<void> _loadSelectedGateway() async {
    final gateway = await GatewayLinkingService.getSelectedGateway();
    if (!mounted) return;
    setState(() {
      _selectedGateway = gateway;
      _loadingGateway = false;
    });
  }

  Future<void> _openGatewayManagement() async {
    await Navigator.of(context).pushNamed(GatewayLinkingService.listRoute);
    if (!mounted) return;
    await _loadSelectedGateway();
  }

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
            bottom: false,
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
                        const SizedBox(height: 14),
                        _GatewaySummaryCard(
                          gateway: _selectedGateway,
                          loading: _loadingGateway,
                          onTap: _openGatewayManagement,
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
                const SpaceBottomBar(active: SpaceTab.home),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GatewaySummaryCard extends StatelessWidget {
  const _GatewaySummaryCard({
    required this.gateway,
    required this.loading,
    required this.onTap,
  });

  final GatewayProfile? gateway;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = gateway == null
        ? 'Link a gateway to manage your home network.'
        : '${gateway!.location ?? gateway!.model} · ${gateway!.firmwareVersion}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF314351), Color(0xFF253540)],
          ),
          border: Border.all(color: const Color(0xFF435766)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                ),
              ),
              child: const Icon(
                Icons.router_outlined,
                color: SpaceColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Gateway',
                    style: SpaceTextStyles.pillMeta.copyWith(
                      color: SpaceColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (loading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      gateway?.name ?? 'No Gateway Linked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SpaceTextStyles.pillTitle.copyWith(fontSize: 17),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SpaceTextStyles.pillMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!loading && gateway != null) ...[
              _GatewayStatusPill(gateway: gateway!),
              const SizedBox(width: 8),
            ],
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: SpaceColors.textPrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GatewayStatusPill extends StatelessWidget {
  const _GatewayStatusPill({required this.gateway});

  final GatewayProfile gateway;

  @override
  Widget build(BuildContext context) {
    final color = switch (gateway.connectionState) {
      GatewayConnectionState.online => const Color(0xFF59D08A),
      GatewayConnectionState.offline => SpaceColors.textMuted,
      GatewayConnectionState.updating => const Color(0xFFF4B740),
      GatewayConnectionState.error => const Color(0xFFF56A6A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 5),
          Text(
            gateway.statusLabel,
            style: SpaceTextStyles.pillMeta.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
              child: RoomImageCover(
                imageUrl: space.imageUrl,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                backgroundGradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C3C4A), Color(0xFF22313C)],
                ),
                overlayGradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x12000000), Color(0x66000000)],
                ),
                placeholderIconColor: SpaceColors.textMuted.withValues(
                  alpha: 0.7,
                ),
                placeholderIconSize: 36,
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

