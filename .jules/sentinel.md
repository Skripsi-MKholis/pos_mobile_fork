
## 2025-02-28 - Hardcoded Supabase Secrets Removed
**Vulnerability:** Found hardcoded `supabaseUrl` and `supabaseAnonKey` in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials can lead to unauthorized access and security breaches.
**Prevention:** Use `String.fromEnvironment` to load secrets securely via compile-time variables (e.g., `--dart-define`) and add validation checks during app initialization to fail fast if required secrets are missing.
