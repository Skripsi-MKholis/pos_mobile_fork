
## 2024-05-24 - [CRITICAL] Fix hardcoded Supabase secrets
**Vulnerability:** Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart` and multiple test scripts (`test_query.dart`, `test_query_http.dart`).
**Learning:** Hardcoding sensitive configuration limits portability and exposes credentials if the repository is made public or shared improperly.
**Prevention:** Use `String.fromEnvironment('VAR_NAME', defaultValue: '')` to pull configuration at build/run time and pass them using `--dart-define=VAR_NAME=value`.
