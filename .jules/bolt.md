## 2024-05-18 - Debouncing Text Inputs
**Learning:** In a Riverpod/Flutter app, repeatedly calling `setState` on every keystroke in a `ShadInput` `onChanged` event forces expensive rebuilds across large UI sections, specifically slowing down list rendering like `productsAsync.when(...)`. This is a frontend performance bottleneck.
**Action:** Always wrap state updates (`setState` or `ref.read().update()`) from text inputs in a `Debouncer` (using `Timer`) when those inputs drive queries/filters over local data or network lists.
