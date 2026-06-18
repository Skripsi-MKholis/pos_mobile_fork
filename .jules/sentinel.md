## 2025-02-14 - Fix Hardcoded Supabase Secrets in Env Class
**Vulnerability:** The Supabase URL and Anon Key were hardcoded in `lib/core/env/env.dart`, meaning these sensitive credentials would be committed to version control and bundled into the app binary, increasing the risk of exposure.
**Learning:** Hardcoding credentials makes it impossible to securely swap environments (e.g., dev, staging, prod) without modifying code, and violates the principle of keeping configuration out of code.
**Prevention:** Use `String.fromEnvironment` and pass secrets securely during build or execution via `--dart-define`. Always validate that required secrets are present early in the app's lifecycle to prevent accidental invalid connections.
