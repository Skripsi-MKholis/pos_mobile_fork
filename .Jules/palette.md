## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2024-05-20 - Adding Tooltips to Interactive Icons
**Learning:** The 'sort' button in the POS category selector was implemented as a generic `InkWell` containing an icon without any accessibility labels. This pattern was likely missed because it isn't explicitly a `ShadIconButton` or an `IconButton`.
**Action:** When auditing the UI for missing tooltips, do not restrict searches only to explicit button widgets; also check custom clickable containers like `InkWell` or `GestureDetector` that act as icon-only buttons.
