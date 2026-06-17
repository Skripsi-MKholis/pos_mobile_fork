## 2025-06-17 - [Hardcoded Supabase Keys]
**Vulnerability:** Supabase Anon Key is hardcoded in lib/core/env/env.dart.
**Learning:** Hardcoded API keys expose backend services and should be passed via --dart-define.
**Prevention:** Use String.fromEnvironment in Dart to read environment variables securely.
