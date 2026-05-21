## 2025-05-24 - [Hardcoded Secrets]
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** Hardcoded secrets can be easily extracted from the application binary.
**Prevention:** Use `--dart-define` to inject secrets at build/run time and read them via `String.fromEnvironment`.
