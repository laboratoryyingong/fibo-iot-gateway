import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  static List<BoxShadow> get softCardShadow => const [
    BoxShadow(
      color: AppColors.shadowSoft,
      offset: Offset(0, 2),
      blurRadius: 10,
    ),
  ];

  static List<BoxShadow> get topBarShadow => const [
    BoxShadow(
      color: AppColors.shadowBar,
      offset: Offset(0, -2),
      blurRadius: 10,
    ),
  ];

  static List<BoxShadow> get iconButtonShadow => const [
    BoxShadow(color: AppColors.shadowSoft, offset: Offset(0, 1), blurRadius: 6),
  ];

  static List<BoxShadow> get promoShadow => const [
    BoxShadow(
      color: AppColors.shadowBlue,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}
