import 'package:flutter/material.dart';

import 'app_colors.dart';

class AuthTokens {
  static const double designWidth = 375;
  static const double designHeight = 812;

  static const double panelRadius = 24;
  static const double fieldRadius = 16;
  static const double tabRadius = 12;
  static const double innerTabRadius = 10;
  static const double buttonRadius = 16;

  static const double panelHorizontalPadding = 24;
  static const double panelContentTop = 40;
  static const double panelContentBottom = 24;

  static const double panelTopSignIn = 228;
  static const double panelTopSignUp = 160;
  static const double panelTopForgot = 228;

  static const double fieldGap = 16;
  static const double selectorHeight = 44;
  static const double selectorPadding = 4;

  static const double badgeSize = 72;
  static const double badgeInnerSize = 40;
  static const double badgeBorderWidth = 1.67;
  static const double badgeRight = 24;

  static const double inputTextSize = 16;
  static const double subtitleSize = 14;
  static const double helperSize = 13;
  static const double avatarCaptionSize = 10;
}

class AuthTextStyles {
  static const heading = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.authTextPrimary,
    height: 1.2,
  );

  static const title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextPrimary,
    letterSpacing: 0.5,
  );

  static const body = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextPrimary,
  );

  static const bodyMuted = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextMuted,
  );

  static const subtitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextMuted,
    height: 1.5,
  );

  static const subtitleBold = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.authLinkSoft,
    height: 1.4,
  );

  static const button = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.authTextPrimary,
  );

  static const caption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextMuted,
  );

  static const tinyCaption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextMuted,
    height: 1.6,
  );
}
