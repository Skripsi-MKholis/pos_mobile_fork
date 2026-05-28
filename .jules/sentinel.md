## 2024-05-18 - [Fix] Hardcoded Supabase Secrets in Env
**Vulnerability:** Hardcoded `supabaseUrl` and `supabaseAnonKey` found in `lib/core/env/env.dart`.
**Learning:** These sensitive values were directly checked into version control, making them publicly accessible and allowing unauthorized access to the Supabase backend.
**Prevention:** Always use environment variables or configuration files that are excluded from version control for sensitive keys. For Dart/Flutter, use `String.fromEnvironment` and pass values via `--dart-define` at build/run time.
