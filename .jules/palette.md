
## 2024-05-24 - [Confirmation Dialogs for Destructive Actions]
**Learning:** Immediate destructive actions like clearing a cart can lead to accidental data loss. Using `showShadDialog` with `ShadButton.destructive` provides an excellent, native-feeling confirmation modal to prevent user frustration.
**Action:** Always wrap high-stakes, destructive actions (delete, clear, remove) in a confirmation modal using the app's standard dialog components, ensuring localized texts are used for the prompt and action buttons.
