## 2025-02-09 - [CRITICAL] Prevent Hardcoded Secrets
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials risk exposure in version control and unauthorized access to backend resources.
**Prevention:** Use environment variables (`String.fromEnvironment`) to pass secrets at build/run time, coupled with fail-fast validation in `main.dart` to ensure they are provided.
