import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fibo_core/theme/app_colors.dart';

class AuthBackgroundImage extends StatelessWidget {
  const AuthBackgroundImage({
    super.key,
    this.overlayOpacity = 0,
    this.showImage = true,
    this.showGlowBlobs = false,
  });

  final double overlayOpacity;
  final bool showImage;
  final bool showGlowBlobs;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthScale = constraints.maxWidth / 375;
          final heightScale = constraints.maxHeight / 812;
          final blurScale = (widthScale + heightScale) / 2;

          Widget glowBlob({
            required double left,
            required double top,
            required double width,
            required double height,
            required Color color,
            required double blurRadius,
          }) {
            return Positioned(
              left: left * widthScale,
              top: top * heightScale,
              width: width * widthScale,
              height: height * heightScale,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurRadius * blurScale,
                  sigmaY: blurRadius * blurScale,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              const ColoredBox(color: AppColors.authBgBase),
              if (showImage)
                Image.asset(
                  'assets/images/auth/auth.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              if (showGlowBlobs)
                glowBlob(
                  left: -1327,
                  top: 208,
                  width: 1518,
                  height: 1011,
                  color: AppColors.authAccentRed,
                  blurRadius: 186.5,
                ),
              if (showGlowBlobs)
                glowBlob(
                  left: 73,
                  top: 170,
                  width: 1629,
                  height: 1085,
                  color: AppColors.authAccentBlue,
                  blurRadius: 233.5,
                ),
              if (overlayOpacity > 0)
                ColoredBox(
                  color: AppColors.authBgBase.withValues(alpha: overlayOpacity),
                ),
            ],
          );
        },
      ),
    );
  }
}
