## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2026-05-21 - Adding confirmation for destructive actions
**Learning:** The 'Clear Cart' action was immediately destructive without a confirmation modal, relying solely on an unlabelled icon. Using `showShadDialog` to present an explicit `ShadDialog` drastically minimizes accidental data loss, which is crucial in a fast-paced POS environment. Incorporating explicit warning styles (e.g., `Colors.red`) clearly signifies the action's destructive nature.
**Action:** Always check high-stakes UI actions (like clearing, deleting, or voiding) and wrap them in a confirmation modal if absent.
