## 2026-06-16 - [Added Clear Cart Confirmation Dialog]
**Learning:** It is crucial to verify context is still mounted after awaiting UI dialog responses. Failing to do this can lead to 'use_build_context_synchronously' lint errors and potential runtime crashes if the user navigated away. Also, remember to clean up text replacement tools artifacts like `.orig` files to keep git history clean.
**Action:** Always wrap post-await state changes in `if (context.mounted)` within UI callbacks. Actively run `git status` or `rm -f *.orig *.diff` after using patch utilities.
