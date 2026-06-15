## 2024-05-24 - [Remove Hardcoded Credentials]
**Vulnerability:** Hardcoded Supabase URL and Anon Key found in `lib/core/env/env.dart`.
**Learning:** These keys were hardcoded, making them available in source control and increasing the risk of unauthorized access or misuse of the Supabase backend.
**Prevention:** Use `String.fromEnvironment` to securely inject credentials via `--dart-define` at compile/run time. Ensure fail-fast validation in `main.dart` to prevent the app from silently failing without proper configuration.
