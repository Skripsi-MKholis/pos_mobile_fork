## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.
## 2024-05-20 - [Hoist Invariant Operations in .where()]
**Learning:** Found multiple instances where `.where()` list filtering contained invariant operations like `DateTime.now()`, `now.subtract()`, and `toLowerCase()`. Since `.where()` processes $O(N)$ times, hoisting these invariants outside the loop prevents redundant memory allocations and system clock calls, reducing potential UI jank during rapid typing or large list filtering.
**Action:** When inspecting list filtering logic across the app, always look for invariants within the filter predicate that can be pre-calculated and hoisted to local variables before the loop.
