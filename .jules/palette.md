# Palette's Journal

## 2024-05-24 - Initial
**Learning:** Initializing journal for Palette.
**Action:** Use this to track UX learnings.

## 2024-06-21 - Add Confirmation Dialog for Destructive Actions
**Learning:** Found a high-stakes UI element (Clear Cart) without any confirmation mechanism, risking accidental data loss for users filling up their POS cart. Users can accidentally tap the delete icon next to the total.
**Action:** Always wrap destructive actions in a confirmation modal (using `showShadDialog`) to prevent accidental data loss, utilizing warning colors like `destructive` to signify the action's nature.
