import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/pairing_tokens.dart';

class GatewayDarkHeader extends StatelessWidget {
  const GatewayDarkHeader({
    super.key,
    required this.title,
    required this.onLeadingTap,
    this.leadingIcon = Icons.arrow_back,
    this.trailingIcon,
    this.onTrailingTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final String title;
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback onLeadingTap;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            _HeaderIcon(icon: leadingIcon, onTap: onLeadingTap),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: PairingTextStyles.headline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (trailingIcon != null)
              _HeaderIcon(icon: trailingIcon!, onTap: onTrailingTap ?? () {})
            else
              const SizedBox(width: 24, height: 24),
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
