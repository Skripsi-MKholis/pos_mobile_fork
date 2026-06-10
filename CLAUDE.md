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

Features: `auth`, `pos`, `product`, `reports`, `dashboard`, `settings`, `customer`, `kds`, `onboarding`

### Offline-first sync

`lib/core/providers/sync_provider.dart` (`SyncNotifier`) watches connectivity. When the device goes online and a user is logged in, it automatically syncs unsynced local Isar records (categories, products, transactions, stock history) to Supabase.

`lib/core/database/isar_service.dart` is a singleton initialized in `main()`. All Isar schemas must be registered there.

### Code generation

Riverpod providers use `@riverpod` annotation. Every provider file `foo.dart` has a generated `foo.g.dart` counterpart. Run `build_runner` after modifying any annotated provider or Isar model. Never edit `.g.dart` files manually.

### Routing & RBAC

`lib/core/router/router.dart` defines all routes. The `redirect` function enforces:
1. Onboarding (first-run check)
2. Auth guard (Supabase session)
3. Store selection guard
4. Role-based access: only `owner` (or Supabase admin) can access `/reports`, `/products`, `/categories`, `/staff-management`, `/manage-tables`, `/store-info`, `/broadcast-notification`, `/smart-analytics`

The `/customer/*` route tree is a separate unauthenticated shell for end-customers (not store staff).

### Environment / credentials

Supabase URL and anon key are hardcoded in `lib/core/env/env.dart`. Firebase config is in `android/app/google-services.json` and `lib/firebase_options.dart`.

### Localization

Uses Flutter's `flutter_localizations` + generated `AppLocalizations`. ARB files live in `lib/l10n/`. Run `flutter gen-l10n` (configured in `l10n.yaml`) to regenerate after editing ARB files.
