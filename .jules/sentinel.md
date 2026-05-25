## 2024-05-25 - [Fix Hardcoded Secrets]
**Vulnerability:** Hardcoded Supabase URL and Anon Key in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials can be extracted from compiled apps, exposing the database. Using `String.fromEnvironment` allows injecting them securely at build/run time.
**Prevention:** Centralize environment variables and use `String.fromEnvironment('VAR_NAME')` instead of literal strings. Do not commit secrets to version control.
