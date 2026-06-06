## 2026-06-06 - [CRITICAL] Prevent Hardcoded Secrets in Config
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`, exposing sensitive credentials directly in the source code.
**Learning:** Hardcoded credentials can easily be checked into version control and exposed, creating a critical security risk.
**Prevention:** Use `String.fromEnvironment()` to securely read secrets passed at build time (e.g., via `--dart-define`), and implement a fail-fast initialization check (e.g., in `main.dart`) to ensure the application doesn't run with missing credentials.
