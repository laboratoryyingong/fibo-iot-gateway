import 'package:flutter/material.dart';

import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';

class PairingHeader extends StatelessWidget {
  const PairingHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onClose,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeaderIcon(icon: Icons.arrow_back, onTap: onBack),
            Text(
              title,
              style: PairingTextStyles.headline.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            _HeaderIcon(icon: Icons.close, onTap: onClose),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, color: AppColors.authTextPrimary, size: 24),
      ),
    );
  }
}
