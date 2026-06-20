import 'package:flutter/material.dart';

import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/auth_tokens.dart';

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.9, -1),
          end: Alignment(0.9, 1),
          colors: [AppColors.authButtonStart, AppColors.authButtonEnd],
        ),
        borderRadius: BorderRadius.circular(AuthTokens.buttonRadius),
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
            : Text(text, style: AuthTextStyles.button),
      ),
    );
  }
}
