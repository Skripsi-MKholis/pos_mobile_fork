## 2024-12-07 - Remove Hardcoded Supabase Credentials
**Vulnerability:** Supabase API URL and Anon Key were hardcoded in `lib/core/env/env.dart`, which exposes backend details to anyone who decompiles the application or accesses the source code.
**Learning:** Hardcoding credentials in client applications creates a critical security risk. It's crucial to load them via environment variables at compile-time instead.
**Prevention:** Use `String.fromEnvironment('VAR_NAME', defaultValue: '')` to inject secrets via `--dart-define` and implement fail-fast checks in `main.dart` to prevent the application from starting without required credentials.
