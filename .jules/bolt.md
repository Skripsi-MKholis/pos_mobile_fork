## 2024-05-20 - [Add Debouncer to ShadInput]
**Learning:** Flutter analyzer failures around 'uri_does_not_exist' usually indicate an issue with dependency resolution or Flutter version mismatch, which is a known issue outlined in the system memory (Dart SDK requirement higher than local). This prevents clean 'flutter analyze' outputs. The code itself for debouncing 'ShadInput' 'onChanged' events directly addresses performance by avoiding expensive filter evaluations on every keystroke.
**Action:** Use 'flutter analyze --no-pub' but interpret the 'uri_does_not_exist' errors for packages/internal files as symptoms of the SDK mismatch rather than code logic errors.

## 2024-05-20 - [Add Debouncer to ShadInput Review]
**Learning:** When creating a Debouncer for search inputs with a 'clear' button, the debouncer timer must be cancelled in the clear button's 'onPressed' callback, otherwise the delayed input will overwrite the cleared state. Adding comments is explicitly part of the required guidelines.
**Action:** Always document optimizations in comments in code. Remember to handle timer cancellation on clear UI actions to prevent state race conditions.

## 2024-05-20 - [Avoid Global Dart Formatting]
**Learning:** Running `dart format .` at the root of a Flutter repository can result in formatting hundreds of unintended files if `.gitignore` is not perfectly configured for dependency directories or generated code, polluting git diffs.
**Action:** When formatting code, strictly use `dart format <specific_file_paths>` for the exact files modified instead of globbing the entire directory.

## 2024-05-20 - [Extracting Invariants in Filters]
**Learning:** Dart array filters (`.where()`) execute the inner predicate function for every single element. Calling `toLowerCase()` on a search query variable *inside* the filter predicate executes that string conversion redundantly N times.
**Action:** Always hoist static or invariant string operations out of the loop and store them in a local variable (e.g., `final q = _searchQuery.toLowerCase();`) before using them in a `.where()` iteration.
