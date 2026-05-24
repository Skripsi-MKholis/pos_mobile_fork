## 2025-02-14 - Fix hardcoded credentials
**Vulnerability:** Supabase URL and anonymous key were hardcoded as constant strings in `lib/core/env/env.dart` and standalone test scripts (`test_query.dart`, `test_query_http.dart`).
**Learning:** These variables leaked sensitive backend information.
**Prevention:** Use `String.fromEnvironment()` in Dart configuration to securely retrieve credentials injected at build time, and avoid leaving standalone ad-hoc test scripts containing sensitive information in the repository.
