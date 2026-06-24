## 2026-06-23 - Add confirmation dialog for destructive action
**Learning:** High-stakes or destructive actions (like clearing a cart, or deleting a product) must always be wrapped in a confirmation modal to prevent accidental data loss. Visual cues like 'destructive' button styles reinforce the warning.
**Action:** Use `showShadDialog` with `ShadButton.destructive` for all future implementations of permanent or severe actions.
