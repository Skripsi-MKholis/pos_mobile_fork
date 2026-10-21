## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2024-05-20 - Adding confirmation to destructive actions
**Learning:** High-stakes actions like clearing a cart ('Kosongkan Keranjang') in a POS application are easy to click by mistake. Wrapping these in a confirmation modal () prevents accidental data loss and frustating user experiences.
**Action:** Always verify if a destructive action (like deleting or clearing) lacks a confirmation step. If it does, implement a standard alert dialog before executing the action.

## 2024-05-20 - Adding confirmation to destructive actions
**Learning:** High-stakes actions like clearing a cart ('Kosongkan Keranjang') in a POS application are easy to click by mistake. Wrapping these in a confirmation modal (`showShadDialog`) prevents accidental data loss and frustating user experiences.
**Action:** Always verify if a destructive action (like deleting or clearing) lacks a confirmation step. If it does, implement a standard alert dialog before executing the action.
