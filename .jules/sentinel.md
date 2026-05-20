## 2025-05-20 - [Hardcoded Supabase Anon Key in Env]
**Vulnerability:** Supabase anon key was hardcoded in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials can easily leak and compromise the Supabase database. Flutter provides `String.fromEnvironment` for passing build-time variables.
**Prevention:** Always use `--dart-define` and `String.fromEnvironment` (or environment variable packages like `flutter_dotenv`) instead of placing API keys or secrets directly in code, even "anon" keys when they grant specific access.
