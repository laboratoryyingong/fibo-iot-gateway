import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/app_theme.dart';
import 'package:fibo_core/theme/auth_tokens.dart';
import '../widgets/auth_background_image.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/auth_top_badges.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Invalid email format';
    return null;
  }

  Future<void> _showMessage(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    final user = ParseUser(null, null, _emailController.text.trim());
    final response = await user.requestPasswordReset();
    setState(() => _isLoading = false);

    if (response.success) {
      await _showMessage('Sent', 'A reset link has been sent to your email.');
      return;
    }

    await _showMessage(
      'Send failed',
      response.error?.message ?? 'Please try again later',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.authDark,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelTop =
                constraints.maxHeight *
                (AuthTokens.panelTopForgot / AuthTokens.designHeight);

            return Stack(
              children: [
                const AuthBackgroundImage(
                  showImage: true,
                  showGlowBlobs: true,
                  overlayOpacity: 0,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: panelTop,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.authBgBase,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AuthTokens.panelRadius),
                        topRight: Radius.circular(AuthTokens.panelRadius),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AuthTokens.panelHorizontalPadding,
                        AuthTokens.panelContentTop,
                        AuthTokens.panelHorizontalPadding,
                        AuthTokens.panelContentBottom,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forgot\nPassword',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(
                              width: 295,
                              child: Text(
                                "Enter your email address and we'll send you a link to reset your password.",
                                style: AuthTextStyles.subtitle,
                              ),
                            ),
                            const SizedBox(height: 30),
                            AuthInputField(
                              controller: _emailController,
                              hint: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 36),
                            SizedBox(
                              width: double.infinity,
                              child: AuthGradientButton(
                                text: 'Send Reset Link',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _handleReset,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: InkWell(
                                onTap: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login'),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Remember your password? Sign In',
                                    textAlign: TextAlign.center,
                                    style: AuthTextStyles.bodyMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AuthTokens.badgeRight,
                  top: panelTop + 40,
                  child: const AuthPanelIconBadge(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
