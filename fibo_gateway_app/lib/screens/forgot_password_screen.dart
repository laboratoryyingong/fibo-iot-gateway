import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
            final panelTop = constraints.maxHeight * (228 / 812);
            final textTheme = Theme.of(context).textTheme;

            return Stack(
              children: [
                Container(color: AppColors.authBgBase),
                Container(color: AppColors.authImagePlaceholder),
                Positioned(
                  left: -constraints.maxWidth * 3.54,
                  top: constraints.maxHeight * 0.256,
                  child: Container(
                    width: constraints.maxWidth * 4.05,
                    height: constraints.maxHeight * 1.245,
                    decoration: const BoxDecoration(
                      color: AppColors.authAccentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.195,
                  top: constraints.maxHeight * 0.209,
                  child: Container(
                    width: constraints.maxWidth * 4.34,
                    height: constraints.maxHeight * 1.336,
                    decoration: const BoxDecoration(
                      color: AppColors.authAccentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
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
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forgot\nPassword',
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Enter your email address and we'll send you a link to reset your password.",
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            _AuthField(
                              controller: _emailController,
                              hint: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: _GradientActionButton(
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Remember your password? Sign In',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.authTextMuted,
                                    ),
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
                  right: 24,
                  top: panelTop + 40,
                  child: IgnorePointer(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.authBgSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.authBgElevated,
                              width: 1.67,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 22,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.authButtonStart, AppColors.authButtonEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.authTextPrimary,
                ),
              )
            : Text(text),
      ),
    );
  }
}
