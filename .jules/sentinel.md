
## 2024-05-20 - [Hardcoded Supabase Credentials]
**Vulnerability:** Hardcoded `supabaseUrl` and `supabaseAnonKey` found in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials are a CRITICAL vulnerability that leak access to the backend. These must be dynamically provided at build/run time.
**Prevention:** Use `String.fromEnvironment()` to securely read environment variables injected via `--dart-define` and implement fail-fast validation in `main.dart` to ensure they are provided.
