## 2024-05-20 - Remove Hardcoded Supabase Secrets
**Vulnerability:** Supabase credentials (URL and Anon Key) were hardcoded directly in `lib/core/env/env.dart`.
**Learning:** Hardcoding credentials exposes sensitive infrastructure access in the source code, which is a critical security vulnerability if the repository is ever compromised or made public.
**Prevention:** Use `String.fromEnvironment()` to inject secrets at build time via `--dart-define` and add fail-fast validation in `main.dart` to ensure the application does not run without required credentials.
