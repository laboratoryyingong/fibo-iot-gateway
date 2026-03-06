import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
            final panelTop =
                constraints.maxHeight *
                (AuthTokens.panelTopSignUp / AuthTokens.designHeight);

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
                              'New \nAccount',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            AuthUserTypeSelector(
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
                            const SizedBox(height: 20),
                            AuthInputField(
                              controller: _emailController,
                              hint: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: AuthTokens.fieldGap),
                            AuthInputField(
                              controller: _firstNameController,
                              hint: 'First Name',
                              validator: (value) => _requiredValidator(
                                value,
                                'Please enter your full name',
                              ),
                            ),
                            if (_isInstaller) ...[
                              const SizedBox(height: AuthTokens.fieldGap),
                              AuthInputField(
                                controller: _businessInfoController,
                                hint: 'Business Info',
                                validator: (value) => _requiredValidator(
                                  value,
                                  'Please enter your business info',
                                ),
                              ),
                            ],
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
                            const SizedBox(height: AuthTokens.fieldGap),
                            AuthInputField(
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
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.authTextMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: AuthTokens.fieldGap),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      checkboxTheme: CheckboxThemeData(
                                        side: const BorderSide(
                                          color: AppColors.authButtonEnd,
                                          width: 2,
                                        ),
                                        fillColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.selected,
                                                  )
                                                  ? AppColors.authBgBase
                                                  : AppColors.authBgBase,
                                            ),
                                        checkColor:
                                            WidgetStateProperty.all<Color>(
                                              AppColors.authButtonEnd,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
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
                                const Expanded(
                                  child: Text(
                                    'I agree to the Terms & Conditions',
                                    style: AuthTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: AuthGradientButton(
                                text: 'Get Started',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _handleSignUp,
                              ),
                            ),
                            const SizedBox(height: 34),
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
                                    'Already have an account? Sign In',
                                    style: AuthTextStyles.bodyMuted,
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
                  right: AuthTokens.badgeRight,
                  top: panelTop + 40,
                  child: AuthAvatarUploadBadge(
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
