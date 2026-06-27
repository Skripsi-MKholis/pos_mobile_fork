## 2026-06-27 - Adding Tooltips to Standard IconButtons
**Learning:** When improving accessibility for standard `IconButton` widgets in Flutter, do not wrap them in an additional `Tooltip` widget. Instead, utilize the built-in `tooltip` property of the `IconButton` itself to provide semantic labels for screen readers and visual hints.
**Action:** Use `IconButton(tooltip: '...', ...)` natively for standard buttons, and reserve wrapping with `Tooltip` for custom composite widgets or custom UI components like `ShadIconButton.outline`.
