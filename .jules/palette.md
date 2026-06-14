## 2025-06-14 - Confirmation for Destructive Actions
**Learning:** High-stakes destructive actions in the UI (e.g., clearing the cart, deleting items) need confirmation modals to prevent accidental data loss. This app uses `showShadDialog` with `ShadButton.destructive()` for explicit warning styles. Localizations must be updated in `.arb` files and generated correctly using `flutter gen-l10n`.
**Action:** When adding or modifying a destructive action button, ensure it's wrapped in a confirmation dialog using established patterns and that all new strings are localized.
