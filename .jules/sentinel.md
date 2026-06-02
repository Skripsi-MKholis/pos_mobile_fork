## 2026-05-26 - [Remove Hardcoded Secrets]
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** These keys were committed directly in the source code, making them vulnerable to unauthorized access if the repository is public or compromised.
**Prevention:** Use `String.fromEnvironment` with `--dart-define` to securely manage and inject secrets during build/runtime, instead of hardcoding them in the codebase.
