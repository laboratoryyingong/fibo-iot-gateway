import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'home_profile_models.dart';

class HomeProfileMembersScreen extends StatelessWidget {
  const HomeProfileMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeProfileMockStore.instance;
    final profileId =
        ModalRoute.of(context)?.settings.arguments as String? ??
        store.selectedProfileId;

    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final profile =
            store.findProfileById(profileId) ?? store.selectedProfile;
        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  title: 'Members',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    itemCount: profile.members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      final member = profile.members[index];
                      return _MemberCard(member: member);
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

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back,
                color: SpaceColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: SpaceColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final HomeProfileMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: SpaceColors.bgElevated,
            child: Text(
              member.initials,
              style: SpaceTextStyles.pillTitle.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: SpaceTextStyles.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: SpaceTextStyles.cardMeta.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(member.email, style: SpaceTextStyles.pillMeta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
