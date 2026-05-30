## 2026-05-30 - [CRITICAL] Prevent Hardcoded API Secrets
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoding credentials exposes them directly in version control and any public repository, increasing the risk of unauthorized access.
**Prevention:** Use `String.fromEnvironment` to read secrets during build/runtime. Provide them securely via `--dart-define` instead of checking them into code. Validation should be added before initialization to fail-fast if secrets are missing.
