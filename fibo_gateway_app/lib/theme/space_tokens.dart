import 'package:flutter/material.dart';

class SpaceColors {
  static const bgBase = Color(0xFF1B242D);
  static const bgSurface = Color(0xFF25313D);
  static const bgElevated = Color(0xFF314252);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF737B8C);
  static const stroke = Color(0xFF3A4A5A);
  static const accentStart = Color(0xFF7773FA);
  static const accentEnd = Color(0xFF5652E5);
}

class SpaceTextStyles {
  static const navTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SpaceColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: SpaceColors.textPrimary,
    height: 1.2,
  );

  static const sectionCount = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SpaceColors.textMuted,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: SpaceColors.textPrimary,
  );

  static const cardMeta = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SpaceColors.textMuted,
  );

  static const pillTitle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SpaceColors.textPrimary,
    height: 1.4,
  );

  static const pillMeta = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SpaceColors.textMuted,
  );
}
