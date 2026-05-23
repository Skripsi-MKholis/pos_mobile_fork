## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.
## 2024-05-20 - Adding Confirmation to Destructive Actions
**Learning:** Destructive actions in this app (like "Kosongkan Keranjang" / Clear Cart) sometimes lack confirmation dialogs, which can lead to accidental data loss in a fast-paced POS environment.
**Action:** Always verify if destructive actions (especially those represented by trash icons or clear functions) are wrapped in a `showShadDialog` confirmation to prevent accidental clicks. Use explicit warning colors (like `Colors.red`) for the confirm button.
