import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'home_profile_models.dart';

class HomeProfileEditScreen extends StatefulWidget {
  const HomeProfileEditScreen({super.key});

  @override
  State<HomeProfileEditScreen> createState() => _HomeProfileEditScreenState();
}

class _HomeProfileEditScreenState extends State<HomeProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _homeNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _profileId = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final store = HomeProfileMockStore.instance;
    final routeProfileId =
        ModalRoute.of(context)?.settings.arguments as String?;
    final profile =
        store.findProfileById(routeProfileId ?? '') ?? store.selectedProfile;
    _profileId = profile.id;

    _homeNameController.text = profile.name;
    _locationController.text = profile.location;
    _emailController.text = profile.ownerEmail;
    _firstNameController.text = profile.ownerFirstName;
    _lastNameController.text = profile.ownerLastName;
    _phoneController.text = profile.ownerPhone;

    _initialized = true;
  }

  @override
  void dispose() {
    _homeNameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        child: Stack(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SpaceColors.bgElevated,
                                border: Border.all(color: SpaceColors.stroke),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 44,
                                color: SpaceColors.textPrimary,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: SpaceColors.bgSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SpaceColors.stroke),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 22,
                                  color: SpaceColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FieldBlock(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'cameron@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _FieldBlock(
                        label: 'First Name',
                        controller: _firstNameController,
                        hint: 'Cameron',
                      ),
                      const SizedBox(height: 14),
                      _FieldBlock(
                        label: 'Last Name',
                        controller: _lastNameController,
                        hint: 'Edwards',
                      ),
                      const SizedBox(height: 14),
                      _FieldBlock(
                        label: 'Phone Number',
                        controller: _phoneController,
                        hint: 'Your Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _FieldBlock(
                        label: 'Home Name',
                        controller: _homeNameController,
                        hint: 'My Home',
                      ),
                      const SizedBox(height: 14),
                      _FieldBlock(
                        label: 'Location',
                        controller: _locationController,
                        hint: 'City',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: InkWell(
                onTap: _saveProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Update',
                    style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    HomeProfileMockStore.instance.updateProfile(
      profileId: _profileId,
      name: _homeNameController.text,
      location: _locationController.text,
      ownerFirstName: _firstNameController.text,
      ownerLastName: _lastNameController.text,
      ownerEmail: _emailController.text,
      ownerPhone: _phoneController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
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
          const Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: SpaceColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SpaceTextStyles.pillTitle.copyWith(
            color: SpaceColors.textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
          style: SpaceTextStyles.pillTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SpaceTextStyles.pillMeta.copyWith(fontSize: 16),
            filled: true,
            fillColor: SpaceColors.bgBase,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SpaceColors.bgElevated),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SpaceColors.bgElevated),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SpaceColors.accentStart),
            ),
          ),
        ),
      ],
    );
  }
}
