## 2024-05-24 - Supabase Credentials Hardcoded in Env Class
**Vulnerability:** Supabase URL and Anon Key were hardcoded as static constants in `lib/core/env/env.dart`.
**Learning:** Even when centralized in a configuration class, storing secrets directly in source control exposes them to anyone with repository access. This is particularly dangerous for public or widely shared repositories.
**Prevention:** Use Dart's `String.fromEnvironment` to inject sensitive values at build/run time via `--dart-define`. Always implement fail-fast validation during app initialization (e.g., in `main.dart`) to ensure these variables are present before the app attempts to connect to external services.
