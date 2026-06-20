import 'package:flutter/material.dart';

import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';

enum PairingActionButtonVariant { primary, neutral }

class PairingActionButton extends StatelessWidget {
  const PairingActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PairingActionButtonVariant.primary,
  });

  final String text;
  final VoidCallback onPressed;
  final PairingActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == PairingActionButtonVariant.primary;
    final colors = isPrimary
        ? const [PairingTokens.accentPrimary, PairingTokens.accentEnd]
        : const [AppColors.white, AppColors.white];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
          ),
        ),
        child: Text(
          text,
          style: PairingTextStyles.bodyBold.copyWith(
            color: isPrimary ? AppColors.authTextPrimary : AppColors.black,
            height: 1,
          ),
        ),
      ),
    );
  }
}
