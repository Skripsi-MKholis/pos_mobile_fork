## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2024-05-31 - Confirming Destructive Actions
**Learning:** Actions resulting in data loss (like clearing the entire cart of products) without a confirmation step frequently lead to user frustration. In this POS app, clearing the cart was instantaneous, risking loss of complex ongoing orders.
**Action:** Always wrap high-stakes destructive UI actions in a confirmation modal (using `showShadDialog`) with a clear warning style (e.g., `Colors.red` for the confirmation button). Ensure new dialog localization strings are added for context-appropriate language.
