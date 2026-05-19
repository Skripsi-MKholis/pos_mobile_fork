## 2024-05-19 - Debouncing Search Inputs
**Learning:** Text inputs that drive list filtering (like `_searchQuery`) trigger `setState` on every keystroke, causing expensive UI rebuilds.
**Action:** Use a `Debouncer` in `onChanged` handlers to delay state updates and reduce unnecessary re-renders.
