import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _theme(
    appColors: AppThemeColors.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    inputFillColor: AppColors.surfaceVariant,
    appBarBackgroundColor: AppColors.background,
    appBarForegroundColor: AppColors.textPrimary,
    borderColor: AppColors.border,
  );

  static ThemeData get dark => _theme(
    appColors: AppThemeColors.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1C1B19),
    ),
    scaffoldBackgroundColor: const Color(0xFF12110F),
    cardColor: const Color(0xFF1C1B19),
    inputFillColor: const Color(0xFF24221F),
    appBarBackgroundColor: const Color(0xFF12110F),
    appBarForegroundColor: Colors.white,
    borderColor: const Color(0xFF34312C),
  );

  static ThemeData _theme({
    required AppThemeColors appColors,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color inputFillColor,
    required Color appBarBackgroundColor,
    required Color appBarForegroundColor,
    required Color borderColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      extensions: [appColors],
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
