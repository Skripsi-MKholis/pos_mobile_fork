## 2024-06-10 - Added Confirmation Dialog for Destructive Action
**Learning:** Destructive actions without confirmation dialogs can lead to data loss and poor user experience.
**Action:** When adding destructive actions (e.g. clear cart, delete item), always wrap the action in a confirmation dialog using `showShadDialog`. Incorporate explicit warning styles (e.g. `ShadButton.destructive()`) to clearly signify the destructive nature of the action. Ensure text is localized in `.arb` files and generate dart files using `dart run build_runner build`.
