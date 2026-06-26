## 2026-06-26 - Prevent Hardcoded Supabase Secrets
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** Application secrets were checked into version control, posing a significant risk of unauthorized access.
**Prevention:** Use `String.fromEnvironment` with fail-fast validation during app initialization to pass secrets via `--dart-define` at build/run time.
