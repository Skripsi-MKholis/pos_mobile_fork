## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.
## 2024-05-20 - [Optimize List Filtering O(N) Operations]
**Learning:** Dart's `.where()` method loops over every item in a collection. Inside Flutter UI, these closures often execute on every rebuild (e.g., as a user types into a search bar). Calling `.toLowerCase()` repeatedly on the search query, re-parsing dates with `DateTime.parse()`, and computing `DateTime.now()` inside the loop introduces significant O(N) overhead.
**Action:** Always extract/hoist invariant values (such as lowercasing the search query or getting the current time) outside the `.where()` loop. Additionally, order conditions inside the loop to evaluate fast, computationally cheap checks (like ID or status matching) before expensive operations (like `contains()` on strings), and implement short-circuit returns `if (query.isEmpty) return true;`.
