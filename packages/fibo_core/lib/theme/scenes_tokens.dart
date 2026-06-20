import 'package:flutter/material.dart';

import 'app_colors.dart';

class ScenesColors {
  static const bgBase = AppColors.authBgBase;
  static const bgSurface = AppColors.authBgSurface;
  static const bgElevated = AppColors.authBgElevated;
  static const bgField = AppColors.authBgBase;

  static const textPrimary = AppColors.authTextPrimary;
  static const textMuted = AppColors.authTextMuted;
  static const textDark = AppColors.authBgBase;

  static const deleteStart = Color(0xFFFF6B6B);
  static const deleteEnd = Color(0xFFE53935);

  static const accentStart = AppColors.authButtonStart;
  static const accentEnd = AppColors.authButtonEnd;
}

class ScenesGradients {
  static const surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ScenesColors.bgElevated, ScenesColors.bgSurface],
  );

  static const primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ScenesColors.accentStart, ScenesColors.accentEnd],
  );

  static const deleteButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ScenesColors.deleteStart, ScenesColors.deleteEnd],
  );
}

class ScenesTextStyles {
  static const navTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: ScenesColors.textPrimary,
    height: 1.4,
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ScenesColors.textPrimary,
    height: 1.2308,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ScenesColors.textPrimary,
  );

  static const cardTitleDark = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ScenesColors.textDark,
  );

  static const body = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ScenesColors.textPrimary,
  );

  static const mutedBody = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ScenesColors.textMuted,
  );

  static const caption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ScenesColors.textMuted,
  );

  static const button = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ScenesColors.textPrimary,
  );

  static const buttonSmall = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ScenesColors.textPrimary,
    height: 1.4,
  );
}

class ScenesRadii {
  static const double card = 16;
  static const double panel = 24;
  static const double icon = 100;
}

class ScenesLayout {
  static const double horizontalPadding = 24;
  static const double navTopPadding = 0;
  static const double sectionGap = 16;
  static const double flowCardHeight = 85;
  static const double flowCardHorizontalPadding = 16;
  static const double flowCardVerticalPadding = 8;
}
