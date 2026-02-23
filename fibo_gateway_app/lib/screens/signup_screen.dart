import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background_image.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _businessInfoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInstaller = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;
  bool _isLoading = false;
  bool _isPickingAvatar = false;
  File? _avatarImage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _businessInfoController.dispose();
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

  Future<void> _showAvatarSourceSheet() async {
    if (_isLoading || _isPickingAvatar) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.authBgSurface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.authTextPrimary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.authTextPrimary,
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isPickingAvatar = true);
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() => _avatarImage = File(file.path));
    } catch (_) {
      await _showMessage(
        'Avatar upload',
        'Unable to select image. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
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

    final email = _emailController.text.trim().toLowerCase();
    final user = ParseUser(email, _passwordController.text, email);

    user.set<String>('fullName', _firstNameController.text.trim());
    user.set<String>(
      'userType',
      _isInstaller ? kUserTypeInstaller : kUserTypeUser,
    );
    if (_isInstaller) {
      user.set<String>('businessInfo', _businessInfoController.text.trim());
    }
    if (_avatarImage != null) {
      final avatarFile = ParseFile(
        _avatarImage!,
        name: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadResponse = await avatarFile.upload();
      if (!uploadResponse.success) {
        setState(() => _isLoading = false);
        await _showMessage(
          'Avatar upload failed',
          uploadResponse.error?.message ?? 'Please choose another image.',
        );
        return;
      }
      user.set<dynamic>('avatar', avatarFile);
    }

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
    return Theme(
      data: AppTheme.authDark,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelTop = constraints.maxHeight * (160 / 812);
            final textTheme = Theme.of(context).textTheme;

            return Stack(
              children: [
                Container(color: AppColors.authBgBase),
                const AuthBackgroundImage(),
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
                              'New\nAccount',
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            _UserTypeSelector(
                              isInstaller: _isInstaller,
                              onChanged: (isInstaller) {
                                setState(() {
                                  _isInstaller = isInstaller;
                                  if (!isInstaller) {
                                    _businessInfoController.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            _AuthField(
                              controller: _emailController,
                              hint: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _firstNameController,
                              hint: 'Full Name',
                              validator: (value) => _requiredValidator(
                                value,
                                'Please enter your full name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isInstaller)
                              _AuthField(
                                controller: _businessInfoController,
                                hint: 'Business Info',
                                validator: (value) => _requiredValidator(
                                  value,
                                  'Please enter your business info',
                                ),
                              ),
                            if (_isInstaller) const SizedBox(height: 16),
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
                            _AuthField(
                              controller: _confirmController,
                              hint: 'Confirm Password',
                              obscureText: _obscureConfirmPassword,
                              validator: _confirmValidator,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.authTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(
                                          () => _agreeToTerms = value ?? false,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'I agree to the Terms & Conditions',
                                      style: textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: _GradientActionButton(
                                text: 'Get Started',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _handleSignUp,
                              ),
                            ),
                            const SizedBox(height: 24),
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
                                    'Already have an account? Sign In',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.authTextMuted,
                                    ),
                                    textAlign: TextAlign.center,
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
                  child: _AvatarUploadButton(
                    imageFile: _avatarImage,
                    isLoading: _isPickingAvatar || _isLoading,
                    onTap: _showAvatarSourceSheet,
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

class _AvatarUploadButton extends StatelessWidget {
  const _AvatarUploadButton({
    required this.imageFile,
    required this.isLoading,
    required this.onTap,
  });

  final File? imageFile;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.authBgSurface,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (imageFile != null)
                ClipOval(
                  child: Image.file(
                    imageFile!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.authBgElevated,
                    width: 1.67,
                  ),
                  color: imageFile == null
                      ? Colors.transparent
                      : AppColors.authBgBase.withValues(alpha: 0.5),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.authTextPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 20,
                        color: AppColors.authTextPrimary,
                      ),
              ),
            ],
          ),
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
