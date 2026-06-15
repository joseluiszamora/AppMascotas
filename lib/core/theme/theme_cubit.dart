import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceLabel on AppThemePreference {
  String get label => switch (this) {
    AppThemePreference.system => 'Sistema',
    AppThemePreference.light => 'Claro',
    AppThemePreference.dark => 'Oscuro',
  };

  IconData get icon => switch (this) {
    AppThemePreference.system => Icons.phone_iphone_rounded,
    AppThemePreference.light => Icons.light_mode_rounded,
    AppThemePreference.dark => Icons.dark_mode_rounded,
  };

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };
}

class ThemeCubit extends Cubit<AppThemePreference> {
  ThemeCubit({required SupabaseClient supabase})
    : _supabase = supabase,
      super(AppThemePreference.system);

  final SupabaseClient _supabase;

  Future<void> loadPreferenceForCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(AppThemePreference.system);
      return;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select('theme_preference')
          .eq('id', userId)
          .maybeSingle();

      emit(_parsePreference(data?['theme_preference'] as String?));
    } catch (_) {
      emit(AppThemePreference.system);
    }
  }

  Future<void> setPreference(AppThemePreference preference) async {
    emit(preference);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'theme_preference': preference.name})
          .eq('id', userId);
    } catch (_) {
      // La preferencia visual ya se aplicó localmente; si falla la persistencia
      // se volverá a usar "system" en la siguiente sesión.
    }
  }

  AppThemePreference _parsePreference(String? value) {
    return switch (value) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }
}
