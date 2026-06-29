## 2024-06-29 - [CRITICAL] Fix hardcoded Supabase credentials
**Vulnerability:** Hardcoded Supabase URL and anonymous key directly in `lib/core/env/env.dart`.
**Learning:** Hardcoded credentials in source control expose sensitive environment details to anyone with read access to the repository, leading to potential unauthorized access or abuse of the Supabase project.
**Prevention:** Always manage environment variables and secrets (like Supabase API keys) securely using `String.fromEnvironment('VAR_NAME', defaultValue: '')` in Dart and passing values via `--dart-define` during build/run, rather than hardcoding them in the codebase. Always add fail-fast validation before initialization (e.g., in `main.dart`) to throw an exception if required credentials are not set.
