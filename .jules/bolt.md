## 2025-02-14 - Add Debouncer to Search Input
**Learning:** Adding a Debouncer for search inputs connected to state updates (`setState()`) is crucial in Flutter for performance. Frequent keystrokes triggering rebuilds and filtering logic simultaneously can lead to UI jank and unresponsiveness.
**Action:** Always wrap text inputs driving search or filter updates in a `Debouncer` class to control state update frequency and optimize the user experience.
