## 2024-05-20 - Adding Tooltips to Icon-Only Buttons
**Learning:** `ShadIconButton.outline` (and similar unlabelled button widgets) frequently lack labels or tooltips out-of-the-box in this POS application, severely impacting screen reader accessibility and discoverability. The Indonesian context ("Scan Barcode", "Kosongkan Keranjang") was necessary to match the UI copy.
**Action:** When inspecting newly added or existing icon-only buttons, prioritize wrapping them with the `Tooltip` widget containing context-appropriate language.

## 2024-05-24 - Native Tooltips for IconButtons
**Learning:** While custom icon buttons like `ShadIconButton.outline` require being wrapped in a `Tooltip` widget, Flutter's native `IconButton` has a built-in `tooltip` property. Using this property is more idiomatic and concise than wrapping it in a `Tooltip` widget.
**Action:** When adding tooltips to standard `IconButton` widgets, use the `tooltip` property instead of wrapping the widget.
