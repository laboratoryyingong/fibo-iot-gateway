import 'package:flutter/material.dart';

import 'app_colors.dart';

class PairingTokens {
  static const String fontPrimary = 'Manrope';
  static const String fontSecondary = 'Poppins';

  static const Color bgBase = AppColors.authBgBase; // #1B242D
  static const Color bgSurface = AppColors.authBgSurface; // #25313D
  static const Color bgElevated = AppColors.authBgElevated; // #314252
  static const Color textPrimary = AppColors.authTextPrimary; // #FFFFFF
  static const Color textMuted = AppColors.authTextMuted; // #737B8C
  static const Color accentPrimary = AppColors.authButtonStart; // #7773FA
  static const Color accentEnd = AppColors.authButtonEnd; // #5652E5

  static const double radiusXs = 5;
  static const double radiusSm = 6;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusFull = 100;

  static const List<double> spacingScale = [
    2,
    4,
    6,
    8,
    10,
    12,
    14,
    16,
    20,
    24,
    40,
    56,
    80,
  ];
}

class PairingTextStyles {
  static const title1 = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: PairingTokens.textPrimary,
    height: 1.2,
  );

  static const title2 = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: PairingTokens.textPrimary,
    height: 1.2,
  );

  static const title3 = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: PairingTokens.textPrimary,
    height: 1.2308,
  );

  static const headline = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: PairingTokens.textPrimary,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: PairingTokens.textPrimary,
  );

  static const bodyBold = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: PairingTokens.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: PairingTokens.textPrimary,
    height: 1.4,
  );

  static const captionBold = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: PairingTokens.textPrimary,
    height: 1.4,
  );

  static const small = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: PairingTokens.textPrimary,
  );

  static const footnotes = TextStyle(
    fontFamily: PairingTokens.fontPrimary,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: PairingTokens.textPrimary,
    height: 1.6,
  );
}
