import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../theme/space_tokens.dart';

/// Account security: sends a password-reset link to the signed-in user's email
/// (uses the standard Parse reset flow — no current password handling here).
class AccountPasswordScreen extends StatefulWidget {
  const AccountPasswordScreen({super.key});

  @override
  State<AccountPasswordScreen> createState() => _AccountPasswordScreenState();
}

class _AccountPasswordScreenState extends State<AccountPasswordScreen> {
  String _email = '';
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (!mounted) return;
    setState(() => _email = user?.emailAddress ?? user?.username ?? '');
  }

  Future<void> _sendReset() async {
    if (_email.isEmpty) return;
    setState(() => _sending = true);
    final user = ParseUser(null, null, _email);
    final response = await user.requestPasswordReset();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = response.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'A reset link has been sent to $_email'
              : 'Could not send reset link: ${response.error?.message ?? 'unknown error'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Account Security',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change password',
                      style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We’ll email a secure link to reset your password. Open it '
                      'on this device to choose a new one.',
                      style: SpaceTextStyles.pillMeta.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SpaceColors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: SpaceColors.textPrimary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _email.isEmpty ? '—' : _email,
                              style: SpaceTextStyles.pillTitle
                                  .copyWith(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _sending || _email.isEmpty ? null : _sendReset,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              SpaceColors.accentStart,
                              SpaceColors.accentEnd,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SpaceColors.textPrimary,
                                ),
                              )
                            : Text(
                                _sent ? 'Resend reset link' : 'Send reset link',
                                style: SpaceTextStyles.pillTitle
                                    .copyWith(fontSize: 16),
                              ),
                      ),
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
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
              child: Text(title, style: SpaceTextStyles.navTitle),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
