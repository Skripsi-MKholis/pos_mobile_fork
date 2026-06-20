## 2025-02-14 - Fix Hardcoded Supabase Secrets
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`, exposing sensitive credentials to anyone with access to the source code.
**Learning:** Hardcoded credentials are a critical security risk. Environment variables and build-time configuration (`--dart-define` with `String.fromEnvironment`) should always be used to inject secrets instead of placing them directly in version control.
**Prevention:** In the future, always initialize credentials using `String.fromEnvironment` and implement fail-fast checks early in the application lifecycle (e.g., in `main.dart`) to ensure the application immediately alerts developers if required environment variables are omitted.
