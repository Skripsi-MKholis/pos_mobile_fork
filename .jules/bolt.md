## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.
## 2026-06-01 - [Hoist invariant toLowerCase() out of list filter loops]
**Learning:** In Dart/Flutter apps displaying potentially large lists of items (like products in a POS), using  repeatedly on the same unchanging  string *inside* a  loop causes O(n) redundant string allocations and computations.
**Action:** Always extract/hoist invariant operations outside of loops (e.g. ) to save memory and CPU cycles when filtering lists.
## 2024-05-20 - [Hoist invariant toLowerCase() out of list filter loops]
**Learning:** In Dart/Flutter apps displaying potentially large lists of items (like products in a POS), using `.toLowerCase()` repeatedly on the same unchanging `_searchQuery` string *inside* a `.where()` loop causes O(n) redundant string allocations and computations.
**Action:** Always extract/hoist invariant operations outside of loops (e.g., `final lowerQuery = _searchQuery.toLowerCase();`) to save memory and CPU cycles when filtering lists.
