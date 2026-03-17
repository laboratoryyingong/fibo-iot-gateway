import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/space_tokens.dart';
import 'home_profile_models.dart';

class HomeProfileMenuScreen extends StatelessWidget {
  const HomeProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeProfileMockStore.instance;
    final profileId =
        ModalRoute.of(context)?.settings.arguments as String? ??
        store.selectedProfileId;
    final profile = store.findProfileById(profileId) ?? store.selectedProfile;

    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: profile.name,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _HeroCover(ownerName: profile.ownerFullName),
                    const SizedBox(height: 24),
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/home/profile/edit', arguments: profile.id),
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.group_outlined,
                      title: 'Members',
                      onTap: () => Navigator.of(context).pushNamed(
                        '/home/profile/members',
                        arguments: profile.id,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.router_outlined,
                      title: 'Gateway Management',
                      onTap: () => Navigator.of(context).pushNamed(
                        GatewayLinkingService.listRoute,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Setting',
                      onTap: () => _showPendingToast(context),
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms of use',
                      onTap: () => _showPendingToast(context),
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.send_outlined,
                      title: 'Contact',
                      onTap: () => _showPendingToast(context),
                    ),
                    const SizedBox(height: 24),
                    _MenuTile(
                      icon: Icons.logout_outlined,
                      title: 'Sign Out',
                      onTap: () => _signOut(context),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Version 1.1',
                      style: SpaceTextStyles.pillMeta.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showPendingToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section will be available soon.')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SpaceTextStyles.navTitle.copyWith(fontSize: 30),
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.close,
                color: SpaceColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: Stack(
        children: [
          Container(
            height: 224,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A4A57), Color(0xFF1B242D)],
              ),
            ),
          ),
          Container(
            height: 224,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x001B242D), Color(0xFF1B242D)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 18,
            child: Text(
              ownerName,
              style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: SpaceColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: SpaceColors.textPrimary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: SpaceTextStyles.pillTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          ],
        ),
      ),
    );
  }
}
