import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settings', style: AppTextStyles.heading28),
                const HeaderActionButton(icon: Icons.notifications),
              ],
            ),
            const SizedBox(height: 12),
            const _SectionLabel('Profile'),
            const _Card(
              children: [
                _ProfileTile(name: 'John Doe', email: 'john.doe@example.com'),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel('Preferences'),
            const _Card(
              children: [
                _RowItem(
                  label: 'Notifications',
                  value: 'On',
                  showDivider: true,
                ),
                _RowItem(label: 'Dark Mode', value: 'Off', showDivider: true),
                _RowItem(label: 'Language', value: 'English'),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel('About & Support'),
            const _Card(
              children: [
                _RowItem(label: 'Help & FAQ', value: '', showDivider: true),
                _RowItem(label: 'Send Feedback', value: '', showDivider: true),
                _RowItem(label: 'App Version', value: '1.0.0'),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.body13Muted.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.body14),
              const SizedBox(height: 2),
              Text(email, style: AppTextStyles.body13Muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body14),
              if (value.isNotEmpty)
                Text(value, style: AppTextStyles.body14Muted)
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
