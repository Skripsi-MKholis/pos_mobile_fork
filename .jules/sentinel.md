## 2024-05-31 - Remove hardcoded API keys
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** Hardcoding API keys exposes them in source control and can be easily extracted from compiled binaries, leading to unauthorized access.
**Prevention:** Use `String.fromEnvironment` to inject configuration during the build process using `--dart-define` and validate them before application startup.
