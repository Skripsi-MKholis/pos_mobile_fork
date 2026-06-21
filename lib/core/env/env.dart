class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase credentials (SUPABASE_URL, SUPABASE_ANON_KEY) must be provided via --dart-define');
    }
  }
}
