
## 2025-02-27 - Hardcoded API Key Exposure
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`.
**Learning:** Checking in secrets to source control, even client-facing tokens like Supabase Anon Keys, triggers security alerts and poses a risk if the repository becomes public or is compromised. Flutter requires a specific way to inject environment variables securely at compile time.
**Prevention:** Use Dart's `String.fromEnvironment('VAR_NAME')` to read values passed via `--dart-define` during compilation. Add fail-fast validation in `main.dart` before initializing third-party services to ensure the app doesn't start without required credentials.
