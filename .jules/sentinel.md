
## 2026-06-19 - Remove Hardcoded API Keys
**Vulnerability:** Found hardcoded `supabaseUrl` and `supabaseAnonKey` in `lib/core/env/env.dart`.
**Learning:** Hardcoding credentials in source code exposes sensitive access to the backend database and API, making it susceptible to unauthorized access and data breaches.
**Prevention:** Use `String.fromEnvironment` combined with Dart defines during build/run to inject environment variables securely, and add a fail-fast validation to ensure the application does not start without required credentials.
