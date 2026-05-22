## 2025-05-22 - [Hardcoded Secrets]
**Vulnerability:** Found hardcoded `supabaseAnonKey` in `lib/core/env/env.dart`.
**Learning:** Hardcoding API keys directly into the source code is a critical vulnerability that can expose the application to unauthorized access.
**Prevention:** Use environment variables, such as `String.fromEnvironment` in Dart, to pass sensitive configuration parameters securely during the build or run time via `--dart-define`.
