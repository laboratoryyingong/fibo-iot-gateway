import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/home_graph.dart';
import '../theme/space_tokens.dart';
import 'home_profile_models.dart';
import 'space_models.dart';

class HomeProfileMembersScreen extends StatefulWidget {
  const HomeProfileMembersScreen({super.key});

  @override
  State<HomeProfileMembersScreen> createState() =>
      _HomeProfileMembersScreenState();
}

class _HomeProfileMembersScreenState extends State<HomeProfileMembersScreen> {
  final HomeProfileMockStore _store = HomeProfileMockStore.instance;
  String? _currentUserId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (!mounted) return;
    setState(() => _currentUserId = user?.objectId);
  }

  String? get _homeId => SpaceMockStore.instance.homeGraph?.homeId;
  bool get _isAdmin => SpaceMockStore.instance.homeGraph?.role == 'admin';

  @override
  Widget build(BuildContext context) {
    final profileId =
        ModalRoute.of(context)?.settings.arguments as String? ??
        _store.selectedProfileId;

    return AnimatedBuilder(
      animation: _store,
      builder: (_, _) {
        final profile =
            _store.findProfileById(profileId) ?? _store.selectedProfile;
        return Scaffold(
          backgroundColor: SpaceColors.bgBase,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  title: 'Members',
                  onBack: () => Navigator.of(context).pop(),
                  onAdd: _isAdmin && _homeId != null ? _openInvite : null,
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    itemCount: profile.members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      final member = profile.members[index];
                      final canRemove = _isAdmin &&
                          _homeId != null &&
                          member.id.isNotEmpty &&
                          member.id != _currentUserId;
                      return _MemberCard(
                        member: member,
                        onRemove: canRemove
                            ? () => _confirmRemove(member)
                            : null,
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

  Future<void> _openInvite() async {
    final homeId = _homeId;
    if (homeId == null) return;
    final result = await showDialog<_InviteResult>(
      context: context,
      builder: (_) => const _InviteMemberDialog(),
    );
    if (result == null) return;
    await _runMutation(() => inviteHomeMember(
          homeId: homeId,
          email: result.email,
          role: result.role,
        ), success: 'Invitation sent');
  }

  Future<void> _confirmRemove(HomeProfileMember member) async {
    final homeId = _homeId;
    if (homeId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SpaceColors.bgElevated,
        title: Text(
          'Remove member',
          style: SpaceTextStyles.pillTitle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Remove ${member.name} from this home?',
          style: SpaceTextStyles.pillMeta.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runMutation(() => removeHomeMember(
          homeId: homeId,
          userId: member.id,
        ), success: 'Member removed');
  }

  /// Runs a member mutation with a busy indicator, refreshes from backend, and
  /// surfaces success/failure as a SnackBar.
  Future<void> _runMutation(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      await HomeProfileMockStore.instance.refreshFromBackend();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, this.onAdd});

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onAdd;

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
          SizedBox(
            width: 44,
            height: 44,
            child: onAdd == null
                ? null
                : InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(
                      Icons.person_add_alt_1_outlined,
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, this.onRemove});

  final HomeProfileMember member;
  final VoidCallback? onRemove;

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
                  _roleLabel(member.role),
                  style: SpaceTextStyles.cardMeta.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(member.email, style: SpaceTextStyles.pillMeta),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: SpaceColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    if (role.isEmpty) return 'Member';
    return role[0].toUpperCase() + role.substring(1);
  }
}

class _InviteResult {
  const _InviteResult(this.email, this.role);
  final String email;
  final String role;
}

class _InviteMemberDialog extends StatefulWidget {
  const _InviteMemberDialog();

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  String _role = 'member';
  String? _error;

  static const _roles = ['admin', 'member', 'guest'];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    Navigator.of(context).pop(_InviteResult(email, _role));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SpaceColors.bgElevated,
      title: Text(
        'Invite member',
        style: SpaceTextStyles.pillTitle.copyWith(fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: SpaceTextStyles.pillMeta,
              errorText: _error,
              filled: true,
              fillColor: SpaceColors.bgBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SpaceColors.stroke),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Role', style: SpaceTextStyles.pillMeta),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _role,
            dropdownColor: SpaceColors.bgElevated,
            style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: SpaceColors.bgBase,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SpaceColors.stroke),
              ),
            ),
            items: [
              for (final r in _roles)
                DropdownMenuItem(
                  value: r,
                  child: Text(r[0].toUpperCase() + r.substring(1)),
                ),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'member'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Invite')),
      ],
    );
  }
}
