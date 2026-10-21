## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.

## 2024-05-20 - [Optimize .where Filter Loops]
**Learning:** Dart's String `.toLowerCase()` allocates a new string. Inside `.where()` or `.map()` loops rendering large lists, invoking it on invariant inputs (like the `searchQuery`) repeatedly is a massive, silent O(N) performance leak. Fast-path checks like `if (query.isEmpty)` can also bypass O(N) item checks entirely. Leaving temporary python/dart scripts in the workspace pollutes the PR.
**Action:** Always hoist invariant `toLowerCase()` conversions OUTSIDE of loops. Add an empty fast-path short-circuit where applicable. Clean up all temporary scripts (using `rm`) before committing.
