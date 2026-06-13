## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.

## 2024-05-20 - [Hoist invariant string operations from iterators]
**Learning:** Found an anti-pattern across product presentation screens where `.toLowerCase()` was evaluated inside `where()` filter iterators for both `_searchQuery` and sometimes list items that could be mapped once. Hoisting `.toLowerCase()` for the query string specifically reduces unnecessary repeated string allocations (O(N) -> O(1) for the query itself).
**Action:** When filtering lists dynamically based on a search query string, ensure to assign `query.toLowerCase()` to a variable *before* the `.where()` loop rather than computing it on every single element check.
