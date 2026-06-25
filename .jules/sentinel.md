## 2025-02-21 - [Hardcoded secrets in Env file]
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoded secrets in client-side config files can be exposed. Using `String.fromEnvironment` allows injecting them at build/run time securely via `--dart-define`.
**Prevention:** Always use environment variables for sensitive configuration details. Ensure initialization code includes a fail-fast mechanism (e.g., throwing an exception in `main.dart` if credentials are not provided) to prevent silent configuration failures in production.
