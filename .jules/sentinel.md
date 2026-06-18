## 2025-02-15 - Hardcoded Supabase Secrets in Env Class
**Vulnerability:** Supabase URL and Anon Key are hardcoded in `lib/core/env/env.dart`.
**Learning:** This exposes sensitive database access credentials directly in the codebase, which can be extracted from source code or compiled applications.
**Prevention:** Use `String.fromEnvironment` to inject environment variables securely during the build process (`--dart-define`), and add a fail-fast validation check on app startup (e.g., in `main.dart`) to ensure they are present.
