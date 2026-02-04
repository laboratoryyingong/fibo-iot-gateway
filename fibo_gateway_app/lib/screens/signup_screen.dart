import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_text_field.dart';
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
    if (text.isEmpty) return '请输入邮箱';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return '邮箱格式不正确';
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return '请输入密码';
    if (text.length < 6) return '密码至少 6 位';
    return null;
  }

  String? _confirmValidator(String? value) {
    if ((value ?? '').isEmpty) return '请再次输入密码';
    if (value != _passwordController.text) return '两次密码不一致';
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
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!_agreeToTerms) {
      await _showMessage('需要同意条款', '请先同意条款再继续。');
      return;
    }

    setState(() => _isLoading = true);
    final user = ParseUser(
      _emailController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
    );
    user.set<String>('fullName', _nameController.text.trim());
    final response = await user.signUp();
    setState(() => _isLoading = false);

    if (response.success) {
      await _showMessage('注册成功', '我们已发送验证邮件，请先完成邮箱验证后再登录。');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    await _showMessage('注册失败', response.error?.message ?? '请稍后再试');
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
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.arrow_back, size: 22, color: AppColors.foreground),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('Create Account', style: AppTextStyles.heading20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (value) => _requiredValidator(value, '请输入姓名'),
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
                            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                          ),
                          const SizedBox(width: 8),
                          Text('I agree to the', style: AppTextStyles.body13Muted),
                          const SizedBox(width: 4),
                          Text('Terms & Conditions', style: AppTextStyles.link14.copyWith(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?', style: AppTextStyles.body14Muted),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
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
