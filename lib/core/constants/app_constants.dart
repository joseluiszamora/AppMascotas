class AppConstants {
  AppConstants._();

  static const String appName = 'App Mascotas';
  static const String supabaseUrl = "https://mchcvcqyogfnkzpicuiq.supabase.co";
  static const String supabaseAnonKey =
      "sb_publishable_KE7G40aP_y9pCWdWeq7RiQ_GPbBTyYY";

  static void validateEnvironment() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL o SUPABASE_ANON_KEY. '
        'Ejecuta Flutter con --dart-define-from-file=.env.',
      );
    }
  }
}
