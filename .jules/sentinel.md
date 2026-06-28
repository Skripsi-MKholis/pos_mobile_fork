
## 2026-06-28 - Prevent Hardcoded API Secrets
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** Hardcoding credentials exposes access directly in source code and VCS. While Supabase anonymous keys have limited permissions, hardcoding them still violates the principle of secrets management and allows uncontrolled scraping or misuse.
**Prevention:** Use `String.fromEnvironment` combined with fail-fast validation in `main.dart` to securely inject configurations via `--dart-define` during build/run.
