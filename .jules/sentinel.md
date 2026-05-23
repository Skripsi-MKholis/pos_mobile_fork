## 2025-02-14 - Replace Hardcoded Supabase Secrets
**Vulnerability:** Hardcoded `supabaseUrl` and `supabaseAnonKey` found in `lib/core/env/env.dart`.
**Learning:** Hardcoding sensitive configuration (like Supabase anon key) exposes secrets in the source control, which can be viewed by anyone with access to the repo. This could lead to unauthorized access to the backend.
**Prevention:** Always use environment variables for sensitive configuration. In Flutter, use `String.fromEnvironment` and pass values via `--dart-define` during the build/run process instead of committing them to the repository.
