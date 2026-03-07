import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/auth_tokens.dart';
import '../widgets/auth_background_image.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/auth_top_badges.dart';
import '../widgets/auth_user_type_selector.dart';

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

  String? _requiredValidator(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
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
      Navigator.of(context).pushReplacementNamed('/home/profile');
      return;
    }

    final errorCode = response.error?.code;
    if (errorCode == ParseError.objectNotFound) {
      await _showMessage(
        'Sign-in failed',
        _isInstaller
            ? 'License key or password is incorrect.'
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
            final panelTop =
                constraints.maxHeight *
                (AuthTokens.panelTopSignIn / AuthTokens.designHeight);

            return Stack(
              children: [
                const AuthBackgroundImage(showImage: true, overlayOpacity: 0),
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
                              'Welcome\nBack',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            AuthUserTypeSelector(
                              isInstaller: _isInstaller,
                              onChanged: (isInstaller) {
                                setState(() => _isInstaller = isInstaller);
                              },
                            ),
                            const SizedBox(height: 28),
                            if (_isInstaller)
                              AuthInputField(
                                controller: _licenseController,
                                hint: 'License Key',
                                validator: (value) => _requiredValidator(
                                  value,
                                  'Please enter your license key',
                                ),
                              )
                            else
                              AuthInputField(
                                controller: _emailController,
                                hint: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                            const SizedBox(height: AuthTokens.fieldGap),
                            AuthInputField(
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
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.authTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: SizedBox(
                                width: 295,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: AuthTextStyles.subtitleBold,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 44),
                            SizedBox(
                              width: double.infinity,
                              child: AuthGradientButton(
                                text: 'Sign In',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _handleLogin,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: InkWell(
                                onTap: () =>
                                    Navigator.of(context).pushNamed('/signup'),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Don’t have an account? Get Started',
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
                    child: Text('👋', style: TextStyle(fontSize: 30)),
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
