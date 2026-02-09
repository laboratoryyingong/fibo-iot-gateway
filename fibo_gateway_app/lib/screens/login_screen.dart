import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
    final user = ParseUser(
      _emailController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
    );
    final response = await user.login();
    setState(() => _isLoading = false);

    if (response.success && response.result is ParseUser) {
      final loggedInUser = response.result as ParseUser;
      final emailVerified = loggedInUser.get<bool>('emailVerified') ?? false;
      if (!emailVerified) {
        await _showMessage('Please verify your email', 'Your email is not verified. Please verify it before signing in.');
        await loggedInUser.logout();
        return;
      }
      await _showMessage('Sign-in successful', 'Welcome back!');
      return;
    }

    await _showMessage('Sign-in failed', response.error?.message ?? 'Please try again later');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back', style: AppTextStyles.heading28),
                      const SizedBox(height: 8),
                      Text('Sign in to continue', style: AppTextStyles.body15Muted),
                      const SizedBox(height: 32),
                      AuthTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        validator: _passwordValidator,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                          child: Text('Forgot Password?', style: AppTextStyles.link14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 24),
                      // Social sign-in options are intentionally hidden for now.
                      // Uncomment this block when enabling Google/Apple sign-in.
                      /*
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border, height: 1)),
                          const SizedBox(width: 16),
                          Text('or', style: AppTextStyles.body14Muted),
                          const SizedBox(width: 16),
                          const Expanded(child: Divider(color: AppColors.border, height: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.public, size: 20),
                        label: const Text('Google'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple, size: 20),
                        label: const Text('Apple'),
                      ),
                      const SizedBox(height: 24),
                      */
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?", style: AppTextStyles.body14Muted),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/signup'),
                            child: Text('Sign Up', style: AppTextStyles.link14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
