class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://nolawradcdkemdyumoqs.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}
