## 2025-02-14 - Fix hardcoded Supabase secrets
**Vulnerability:** Supabase API URL and Anon Key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials risk exposure in public repositories and make credential rotation difficult.
**Prevention:** Always use `String.fromEnvironment` for passing sensitive configuration variables dynamically via `--dart-define` at build/run time, and add fail-fast validation to catch missing configurations early.
