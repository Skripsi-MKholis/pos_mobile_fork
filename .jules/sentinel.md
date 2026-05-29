
## 2026-05-29 - Fix hardcoded Supabase credentials
**Vulnerability:** Hardcoded `supabaseUrl` and `supabaseAnonKey` found directly in `lib/core/env/env.dart`.
**Learning:** Hardcoding sensitive configuration values exposes them in source control, making it a critical risk if the repository is public or compromised.
**Prevention:** Always use environment variables (e.g., `String.fromEnvironment` in Dart) to pass secrets at build/run time (via `--dart-define`), keeping them out of the source code.
