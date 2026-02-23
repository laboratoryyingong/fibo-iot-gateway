import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/header_action_button.dart';
import '../widgets/password_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _selectedUserType = kUserTypeUser;
  bool _agreeToTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  String? _confirmValidator(String? value) {
    if ((value ?? '').isEmpty) return 'Please re-enter your password';
    if (value != _passwordController.text) return 'Passwords do not match';
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

  Future<void> _handleSignUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!_agreeToTerms) {
      await _showMessage(
        'Terms acceptance required',
        'Please accept the terms before continuing.',
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = ParseUser(
      _emailController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
    );
    user.set<String>('fullName', _nameController.text.trim());
    user.set<String>('userType', _selectedUserType);
    final response = await user.signUp();
    setState(() => _isLoading = false);

    if (response.success) {
      await _showMessage(
        'Sign-up successful',
        'We sent a verification email. Please verify your email before signing in.',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    await _showMessage(
      'Sign-up failed',
      response.error?.message ?? 'Please try again later',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HeaderActionButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Create Account',
                            style: AppTextStyles.heading20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (value) => _requiredValidator(
                          value,
                          'Please enter your full name',
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      _UserTypeSelector(
                        selectedType: _selectedUserType,
                        onChanged: (type) =>
                            setState(() => _selectedUserType = type),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Password',
                        hint: 'Create a password',
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _passwordValidator,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        controller: _confirmController,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _confirmValidator,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) =>
                                setState(() => _agreeToTerms = value ?? false),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'I agree to the',
                            style: AppTextStyles.body13Muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terms & Conditions',
                            style: AppTextStyles.link14.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: AppTextStyles.body14Muted,
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/login'),
                            child: Text('Sign In', style: AppTextStyles.link14),
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

class _UserTypeSelector extends StatelessWidget {
  const _UserTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: AppTextStyles.body14.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypeOption(
                label: 'User',
                value: kUserTypeUser,
                selected: selectedType == kUserTypeUser,
                onTap: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TypeOption(
                label: 'Installer',
                value: kUserTypeInstaller,
                selected: selectedType == kUserTypeInstaller,
                onTap: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body14.copyWith(
            color: selected
                ? AppColors.primaryForeground
                : AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
