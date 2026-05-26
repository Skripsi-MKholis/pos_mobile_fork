## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.

## 2026-05-26 - [Hoist invariant string conversion outside loops]
**Learning:** When filtering or sorting lists using `.where()`, any invariant string operations like `.toLowerCase()` applied to search variables will be redundantly re-calculated O(N) times during each build pass, hurting frontend scrolling and rendering performance on large lists. This is a common performance anti-pattern in the codebase.
**Action:** Always scan for redundant string allocations or invariant computations inside , , or  functions and hoist them outside of the block logic.

## 2026-05-26 - [Hoist invariant string conversion outside loops]
**Learning:** When filtering or sorting lists using .where(), any invariant string operations like .toLowerCase() applied to search variables will be redundantly re-calculated O(N) times during each build pass, hurting frontend scrolling and rendering performance on large lists. This is a common performance anti-pattern in the codebase.
**Action:** Always scan for redundant string allocations or invariant computations inside .where(), .map(), or .sort() functions and hoist them outside of the block logic.
