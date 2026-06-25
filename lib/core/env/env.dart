class Env {
  // Security Fix: Supabase credentials are now loaded from environment variables
  // using --dart-define during build/run to prevent hardcoding secrets.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}
