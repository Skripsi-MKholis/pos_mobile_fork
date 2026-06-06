## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.

## 2024-05-20 - [Performance Optimization: Hoist Invariant Operations from loops]
**Learning:** Found multiple instances where `_searchQuery.toLowerCase()` and `DateTime.now()` evaluations were happening inside `.where()` iterable loop callbacks, causing unnecessary O(N) memory allocations and evaluations during string comparisons for filtering.
**Action:** Always pre-compute and hoist these types of invariants outside of iteration loops (`.where`, `.map`, `.forEach`) and pass the constant to the closure, particularly for dynamic operations like `.toLowerCase()` and time instantiations.
