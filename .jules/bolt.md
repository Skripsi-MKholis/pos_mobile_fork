## 2024-05-17 - [Flutter TextField setState bottleneck]
**Learning:** Calling setState unconditionally inside TextField or ShadInput onChanged callback will cause excessive UI layout reflows and stuttering performance on list screens when the user types rapidly.
**Action:** Always throttle textual search filter state updates using the Debouncer class. And remember to use debouncer.cancel() when the clear button is pressed so that out of sync results don't re-appear on empty fields.
