import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'auth_tokens.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        outline: AppColors.border,
        error: AppColors.destructive,
        onError: AppColors.white,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTextStyles.heading28,
        headlineSmall: AppTextStyles.heading24,
        titleLarge: AppTextStyles.heading20,
        bodyLarge: AppTextStyles.body16,
        bodyMedium: AppTextStyles.body15Muted,
        bodySmall: AppTextStyles.body14,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppTextStyles.body15Muted,
        labelStyle: AppTextStyles.body14,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          textStyle: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          textStyle: AppTextStyles.body14,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.card,
        ),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedLabelStyle: AppTextStyles.body13Muted.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body13Muted,
        elevation: 0,
      ),
    );
  }

  // Dark auth theme derived from design/tokens.md and design/auth.pen
  static ThemeData get authDark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          const ColorScheme(
            brightness: Brightness.dark,
            primary: AppColors.authAccentBlue,
            onPrimary: AppColors.authTextPrimary,
            secondary: AppColors.authBgElevated,
            onSecondary: AppColors.authTextPrimary,
            error: AppColors.authAccentRed,
            onError: AppColors.authTextPrimary,
            surface: AppColors.authBgBase,
            onSurface: AppColors.authTextPrimary,
          ).copyWith(
            outline: AppColors.authBgElevated,
            onSurfaceVariant: AppColors.authTextMuted,
          ),
      scaffoldBackgroundColor: AppColors.authBgBase,
    );

    const textTheme = TextTheme(
      headlineMedium: AuthTextStyles.heading,
      titleLarge: AuthTextStyles.title,
      bodyLarge: AuthTextStyles.body,
      bodyMedium: AuthTextStyles.subtitle,
      bodySmall: AuthTextStyles.caption,
      labelLarge: AuthTextStyles.button,
      labelMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.authTextPrimary,
      ),
      labelSmall: AuthTextStyles.tinyCaption,
    );

    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.authBgBase,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.authTextMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 24,
          minWidth: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.authBgElevated,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.authBgElevated,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.authAccentBlue,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.authTextPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: AuthTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.authBgElevated, width: 1),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.authButtonEnd
              : AppColors.authBgBase,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.authBgElevated,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.authTextMuted),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  static ThemeData get signUpDark => authDark;
}
