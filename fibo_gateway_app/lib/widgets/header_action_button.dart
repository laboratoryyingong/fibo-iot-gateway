import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.foreground,
    this.shadow = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow ? AppDecorations.iconButtonShadow : null,
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );

    if (onTap == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: child,
    );
  }
}
