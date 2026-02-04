import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String primaryFont = 'JetBrains Mono';
  static const String secondaryFont = 'Geist';

  static const heading32 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const heading28 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const heading24 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const heading20 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );

  static const body16 = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const body15Muted = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static const body14 = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
  );

  static const body14Muted = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static const body13Muted = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static const link14 = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const statusTime = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );
}
