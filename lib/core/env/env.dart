class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nolawradcdkemdyumoqs.supabase.co',
  );

  // 🛡️ Sentinel: Removed hardcoded API key to prevent secret leakage.
  // Pass it at build/run time via: --dart-define=SUPABASE_ANON_KEY=your_key_here
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
