## 2024-05-24 - Hardcoded Supabase Secrets Removed
**Vulnerability:** Hardcoded `supabaseAnonKey` and `supabaseUrl` in `lib/core/env/env.dart`.
**Learning:** Hardcoding API keys and URLs in source code exposes them to anyone with access to the repository, leading to potential unauthorized access and data breaches.
**Prevention:** Use `String.fromEnvironment` to load secrets at build/runtime via `--dart-define` arguments. Add fail-fast validation in `main.dart` to ensure the application does not start without required configuration.
