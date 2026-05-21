class AppConstants {
  AppConstants._();

  static const String appName = 'App Mascotas';
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static void validateEnvironment() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL o SUPABASE_ANON_KEY. '
        'Ejecuta Flutter con --dart-define-from-file=.env.',
      );
    }
  }
}
