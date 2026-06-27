## 2026-06-27 - [CRITICAL] Prevent Hardcoded Secrets in Config
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`, exposing sensitive credentials if the codebase is shared.
**Learning:** Hardcoding credentials makes the app insecure and violates best practices for managing environment variables.
**Prevention:** Use `String.fromEnvironment('VAR_NAME', defaultValue: '')` to inject secrets via `--dart-define` at build/run time. Always add fail-fast validation in `main.dart` before initialization to ensure required credentials are set.
