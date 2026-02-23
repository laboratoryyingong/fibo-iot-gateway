import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthBackgroundImage extends StatelessWidget {
  const AuthBackgroundImage({super.key, this.overlayOpacity = 0.28});

  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth/auth.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          ColoredBox(
            color: AppColors.authBgBase.withValues(alpha: overlayOpacity),
          ),
        ],
      ),
    );
  }
}
