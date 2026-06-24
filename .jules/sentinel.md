## 2026-06-24 - Secure Supabase Configuration
**Vulnerability:** Hardcoded Supabase credentials (SUPABASE_URL and SUPABASE_ANON_KEY) in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials can be easily extracted from source code or compiled binaries, posing a severe security risk, especially for critical infrastructure like databases.
**Prevention:** Use `String.fromEnvironment` to securely inject configuration via `--dart-define` during build time, and add fail-fast validation in `main.dart` to ensure the app doesn't run without necessary configuration.
