import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/auth_tokens.dart';

class AuthPanelIconBadge extends StatelessWidget {
  const AuthPanelIconBadge({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.authBgSurface,
    this.iconBorderColor = AppColors.authBgElevated,
  });

  final Widget child;
  final Color backgroundColor;
  final Color iconBorderColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: AuthTokens.badgeSize,
        height: AuthTokens.badgeSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: AuthTokens.badgeInnerSize,
          height: AuthTokens.badgeInnerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: iconBorderColor,
              width: AuthTokens.badgeBorderWidth,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class AuthAvatarUploadBadge extends StatelessWidget {
  const AuthAvatarUploadBadge({
    super.key,
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
        child: SizedBox(
          width: AuthTokens.badgeSize,
          height: AuthTokens.badgeSize,
          child: Stack(
            children: [
              Container(
                width: AuthTokens.badgeSize,
                height: AuthTokens.badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.authBgElevated, width: 2),
                ),
                child: imageFile == null
                    ? null
                    : ClipOval(
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          width: AuthTokens.badgeSize,
                          height: AuthTokens.badgeSize,
                        ),
                      ),
              ),
              Positioned(
                left: 24,
                top: 16,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.authTextPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        size: 24,
                        color: AppColors.authTextMuted,
                      ),
              ),
              const Positioned(
                left: 8,
                top: 40,
                width: 56,
                child: Text(
                  'Upload',
                  textAlign: TextAlign.center,
                  style: AuthTextStyles.tinyCaption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
