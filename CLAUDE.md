# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build APK (release)
flutter build apk --release

# Install dependencies
flutter pub get

# Generate code (Riverpod, Isar models)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch and regenerate on change
flutter pub run build_runner watch --delete-conflicting-outputs

# Lint
flutter analyze

# Run tests
flutter test
```

## Architecture

This is a Flutter POS (Point of Sale) mobile app called **Parzello POS**, using:
- **State management**: Riverpod (`flutter_riverpod` + `riverpod_annotation` + code generation)
- **Backend**: Supabase (auth, database, realtime)
- **Local DB**: Isar (offline storage and sync queue)
- **Navigation**: go_router (`lib/core/router/router.dart`)
- **UI**: shadcn_ui component library with a fixed light theme (Luma - Stone/Lime color scheme)
- **Auth**: Firebase (analytics, messaging/FCM) + Supabase (user auth, data)

### Feature structure

`lib/features/<feature>/` follows a consistent layout:
- `presentation/` — screens and widgets
- `providers/` — Riverpod providers (`.dart` source + `.g.dart` generated)
- `models/` — data models (customer feature only; core models live in `lib/core/models/`)

Features: `auth`, `pos`, `product`, `reports`, `dashboard`, `settings`, `customer`, `onboarding`

### Offline-first sync

`lib/core/providers/sync_provider.dart` (`SyncNotifier`) watches connectivity. When the device goes online and a user is logged in, it automatically syncs unsynced local Isar records (categories, products, transactions, stock history) to Supabase.

`lib/core/database/isar_service.dart` is a singleton initialized in `main()`. All Isar schemas must be registered there.

### Code generation

Riverpod providers use `@riverpod` annotation. Every provider file `foo.dart` has a generated `foo.g.dart` counterpart — run `build_runner` after modifying any annotated provider and never edit these `.g.dart` files manually.

Isar is pinned to `isar_community` 3.2.1 (not the abandoned `isar` package; import as `package:isar_community/isar.dart`) to get 16 KB-page-aligned native binaries for Google Play. Its generator isn't wired into `build_runner` (3.2.1 generator is broken on current Dart; newer generators need an analyzer/build version that conflicts with `riverpod_generator` 2.x), so the `.g.dart` files under `lib/core/models/` are **hand-maintained** — `build.yaml` excludes that path from `--delete-conflicting-outputs`. If you change an `@collection` model, regenerate its `.g.dart` externally (e.g. a throwaway project with `isar_community_generator` 3.2.1) and keep the schema `version:` string equal to `Isar.version` ('3.2.1'), or the const `CollectionSchema` assertion throws at compile time.

### Routing & RBAC

`lib/core/router/router.dart` defines all routes. The `redirect` function enforces:
1. Onboarding (first-run check)
2. Auth guard (Supabase session)
3. Store selection guard
4. Role-based access: after the "Penyesuaian Fitur Role Kasir" change, only `/staff-management` and `/store-info` are owner-only (see the `restrictedRoutes` list in `router.dart`). Reports, products, categories, and Smart Analytics are open to `Karyawan` as well.

The `/customer/*` route tree is a separate unauthenticated shell for end-customers (not store staff).

### Environment / credentials

Supabase URL and anon key are hardcoded in `lib/core/env/env.dart`. Firebase config is in `android/app/google-services.json` and `lib/firebase_options.dart`.

The Smart Analitik LSTM/prediction endpoint (`lib/core/env/env.dart` — `lstmHfUrl`, `lstmLocalPhysicalUrl`) is overridable at build/run time via `--dart-define`, e.g. `flutter run --dart-define=LSTM_HF_URL=https://xxx.hf.space`, or in bulk via `--dart-define-from-file=env.json` (copy `env.example.json`, gitignored). Falls back to the hardcoded defaults if not provided.

### Forecasting (Smart Analitik)

Layered under `lib/features/reports/`, per `Dokumen/28 Juli - Improve Fitur LSTM.md`:

- `models/` — plain data (`ForecastResult`, `ForecastInput`, `ForecastMode`, …). No Flutter types; `Color`/`IconData` mapping lives in `presentation/widgets/recommendation_style.dart`.
- `domain/` — pure functions (`tab_aggregator.dart`, `forecast_accuracy.dart`, `local_forecast_estimator.dart`). No I/O, no `Random`, no implicit `DateTime.now()` — this is what the unit tests in `test/reports/` cover.
- `data/` — `lstm_api_client.dart` (HTTP, warmup + adaptive timeout, v2 with automatic v1 fallback) and `smart_analytics_repository.dart` (RPC/query, snapshots, offline cache).
- `providers/` — `smart_analytics_provider.dart` orchestrates; `forecast_provider.dart` is the **read-only shared source** for Dashboard/Stock/notifications. Those features must never call the model themselves.

Two rules that are easy to break:

1. **`metadata.model_used` decides the label.** Only `lstm`/`lstm_finetuned` may be shown as "Prediksi LSTM" (`ForecastMode.isLstm`). Baselines and on-device estimates get their own labels.
2. **Never fill missing history with forecast values.** Days with no transactions are `0` with `hasActual: false`; dates outside the model horizon are skipped, not extrapolated.

New DB objects (`ai_forecast_points`, RPC `get_forecast_input`, RPC `evaluate_forecast_points`, extra `smart_analytics_snapshots` columns) live in `supabase/migrations/20260728_lstm_forecast.sql`. The client treats all of them as optional and degrades to the old path when they are absent, so the migration can be applied independently of a release.

### Localization

Uses Flutter's `flutter_localizations` + generated `AppLocalizations`. ARB files live in `lib/l10n/`. Run `flutter gen-l10n` (configured in `l10n.yaml`) to regenerate after editing ARB files.
