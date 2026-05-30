## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2026-05-30 - Add Confirmation Dialog for Destructive Actions
**Learning:** High-stakes actions like clearing a shopping cart () mapped directly to icon-only buttons can lead to accidental data loss. This app uses , and wrapping such actions in a  with an explicitly styled  significantly improves safety without compromising design consistency.
**Action:** When adding or reviewing buttons that trigger destructive or irreversible state changes, always verify if a confirmation modal exists. If not, implement one using .

## 2024-05-30 - Add Confirmation Dialog for Destructive Actions
**Learning:** High-stakes actions like clearing a shopping cart (`clearCart()`) mapped directly to icon-only buttons can lead to accidental data loss. This app uses `shadcn_flutter`, and wrapping such actions in a `ShadDialog` with an explicitly styled `ShadButton.destructive` significantly improves safety without compromising design consistency.
**Action:** When adding or reviewing buttons that trigger destructive or irreversible state changes, always verify if a confirmation modal exists. If not, implement one using `showShadDialog`.
