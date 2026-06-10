## 2025-02-28 - [Removed Hardcoded Supabase Secrets]
**Vulnerability:** Found `supabaseUrl` and `supabaseAnonKey` hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoding secrets exposes them in source control and client builds. Dart's `String.fromEnvironment` should be used instead to pass secrets at build/run time.
**Prevention:** Use `String.fromEnvironment` for secrets and implement a fail-fast validation check in `main.dart` before initialization to ensure required credentials are provided via `--dart-define`, preventing silent failures.
