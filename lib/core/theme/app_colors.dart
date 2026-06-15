import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.pastelPink,
    required this.pastelGreen,
    required this.pastelBlue,
    required this.pastelYellow,
    required this.pastelPurple,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.lostPet,
    required this.foundPet,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color pastelPink;
  final Color pastelGreen;
  final Color pastelBlue;
  final Color pastelYellow;
  final Color pastelPurple;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color lostPet;
  final Color foundPet;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  static const light = AppThemeColors(
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    pastelPink: AppColors.pastelPink,
    pastelGreen: AppColors.pastelGreen,
    pastelBlue: AppColors.pastelBlue,
    pastelYellow: AppColors.pastelYellow,
    pastelPurple: AppColors.pastelPurple,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    lostPet: AppColors.lostPet,
    foundPet: AppColors.foundPet,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
  );

  static const dark = AppThemeColors(
    primary: AppColors.primary,
    primaryLight: Color(0xFF3B2B12),
    primaryDark: Color(0xFFFFC66B),
    background: Color(0xFF12110F),
    surface: Color(0xFF1C1B19),
    surfaceVariant: Color(0xFF24221F),
    border: Color(0xFF34312C),
    pastelPink: Color(0xFF3A2023),
    pastelGreen: Color(0xFF1F3322),
    pastelBlue: Color(0xFF1D2A3F),
    pastelYellow: Color(0xFF3B2B12),
    pastelPurple: Color(0xFF30243C),
    textPrimary: Color(0xFFF6F2EA),
    textSecondary: Color(0xFFC5BEB2),
    textHint: Color(0xFF82796C),
    lostPet: Color(0xFFFF7C78),
    foundPet: Color(0xFF8FDB8C),
    success: Color(0xFF8FDB8C),
    warning: AppColors.warning,
    error: Color(0xFFFF7C78),
    info: Color(0xFF80D8FF),
  );

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? pastelPink,
    Color? pastelGreen,
    Color? pastelBlue,
    Color? pastelYellow,
    Color? pastelPurple,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? lostPet,
    Color? foundPet,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      pastelPink: pastelPink ?? this.pastelPink,
      pastelGreen: pastelGreen ?? this.pastelGreen,
      pastelBlue: pastelBlue ?? this.pastelBlue,
      pastelYellow: pastelYellow ?? this.pastelYellow,
      pastelPurple: pastelPurple ?? this.pastelPurple,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      lostPet: lostPet ?? this.lostPet,
      foundPet: foundPet ?? this.foundPet,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      pastelPink: Color.lerp(pastelPink, other.pastelPink, t)!,
      pastelGreen: Color.lerp(pastelGreen, other.pastelGreen, t)!,
      pastelBlue: Color.lerp(pastelBlue, other.pastelBlue, t)!,
      pastelYellow: Color.lerp(pastelYellow, other.pastelYellow, t)!,
      pastelPurple: Color.lerp(pastelPurple, other.pastelPurple, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      lostPet: Color.lerp(lostPet, other.lostPet, t)!,
      foundPet: Color.lerp(foundPet, other.foundPet, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors {
    return Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
  }
}

class AppColors {
  AppColors._();

  // Primario — naranja cálido
  static const Color primary = Color(0xFFE89B1C);
  static const Color primaryLight = Color(0xFFF9EDC8);
  static const Color primaryDark = Color(0xFFBF7A0A);

  // Fondo
  static const Color background = Color(0xFFF8F5EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F4EE);
  static const Color border = Color(0xFFEDE9E1);

  // Pastel secundarios
  static const Color pastelPink = Color(0xFFF7D9D9);
  static const Color pastelGreen = Color(0xFFDDEFD9);
  static const Color pastelBlue = Color(0xFFDDE8FF);
  static const Color pastelYellow = Color(0xFFF9EDC8);
  static const Color pastelPurple = Color(0xFFE8DDF9);

  // Texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);

  // Semánticos
  static const Color lostPet = Color(0xFFEF5350);
  static const Color foundPet = Color(0xFF66BB6A);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFE89B1C);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF4FC3F7);
}
