import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isInstaller = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Invalid email format';
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter your password';
    if (text.length < 6) return 'Password must be at least 6 characters';
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

  Future<void> _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);

    final rawAccount = _isInstaller
        ? _licenseController.text.trim()
        : _emailController.text.trim();
    final account = rawAccount.contains('@')
        ? rawAccount.toLowerCase()
        : rawAccount;

    final user = ParseUser(account, _passwordController.text, account);
    user.set<String>(
      'userType',
      _isInstaller ? kUserTypeInstaller : kUserTypeUser,
    );

    final response = await user.login();
    setState(() => _isLoading = false);

    if (response.success && response.result is ParseUser) {
      final loggedInUser = response.result as ParseUser;
      final emailVerified = loggedInUser.get<bool>('emailVerified') ?? false;
      if (!emailVerified && !_isInstaller) {
        await _showMessage(
          'Please verify your email',
          'Your email is not verified. Please verify it before signing in.',
        );
        await loggedInUser.logout();
        return;
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(resolveHomeRoute(loggedInUser));
      return;
    }

    final errorCode = response.error?.code;
    if (errorCode == ParseError.objectNotFound) {
      await _showMessage(
        'Sign-in failed',
        _isInstaller
            ? 'Email or password is incorrect.'
            : 'Email or password is incorrect, or your email is not verified yet. Please verify your email and try again.',
      );
      return;
    }

    await _showMessage(
      'Sign-in failed',
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
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;

            return Stack(
              children: [
                Container(color: AppColors.authBgBase),
                Container(color: AppColors.authImagePlaceholder),
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
                              'Welcome\nBack',
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            _UserTypeSelector(
                              isInstaller: _isInstaller,
                              onChanged: (isInstaller) {
                                setState(() => _isInstaller = isInstaller);
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_isInstaller)
                              _AuthField(
                                controller: _licenseController,
                                hint: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              )
                            else
                              _AuthField(
                                controller: _emailController,
                                hint: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _passwordController,
                              hint: 'Password',
                              obscureText: _obscurePassword,
                              validator: _passwordValidator,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.authTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.authLinkSoft,
                                  textStyle: textTheme.labelMedium,
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: _GradientActionButton(
                                text: 'Sign In',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _handleLogin,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: InkWell(
                                onTap: () =>
                                    Navigator.of(context).pushNamed('/signup'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Don’t have an account? Get Started',
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
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  top: panelTop + 56,
                  child: IgnorePointer(
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.authBgElevated,
                          width: 1.67,
                        ),
                      ),
                      child: const Icon(
                        Icons.waving_hand_outlined,
                        size: 20,
                        color: AppColors.authTextPrimary,
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

class _UserTypeSelector extends StatelessWidget {
  const _UserTypeSelector({required this.isInstaller, required this.onChanged});

  final bool isInstaller;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 42,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.authTabBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              isLeft: true,
              active: !isInstaller,
              icon: Icons.person_outline,
              label: 'User',
              textTheme: textTheme,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _RoleTab(
              isLeft: false,
              active: isInstaller,
              icon: Icons.engineering_outlined,
              label: 'Installer',
              textTheme: textTheme,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.isLeft,
    required this.active,
    required this.icon,
    required this.label,
    required this.textTheme,
    required this.onTap,
  });

  final bool isLeft;
  final bool active;
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isLeft ? 12 : 0),
      bottomLeft: Radius.circular(isLeft ? 12 : 0),
      topRight: Radius.circular(isLeft ? 0 : 12),
      bottomRight: Radius.circular(isLeft ? 0 : 12),
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.authButtonStart,
                      AppColors.authButtonEnd,
                    ],
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active
                    ? AppColors.authTextPrimary
                    : AppColors.authTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: active
                      ? AppColors.authTextPrimary
                      : AppColors.authTextMuted,
                ),
              ),
            ],
          ),
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
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
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
