## 2024-05-30 - [Hardcoded Supabase Credentials]
**Vulnerability:** Supabase URL and anon key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoding secrets exposes them in version control and binaries.
**Prevention:** Use `String.fromEnvironment` and fail-fast validation in `main.dart` to enforce passing credentials via `--dart-define`.
