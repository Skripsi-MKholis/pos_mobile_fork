## 2024-06-13 - Add confirmation dialog to destructive "clear cart" action
**Learning:** Destructive actions without confirmation are a poor UX pattern, especially in a fast-paced point-of-sale environment. Adding a confirmation dialog using standard Shadcn components improves the safety and confidence of using the interface.
**Action:** When working on destructive actions (deleting, clearing, wiping), always add a confirmation dialog (e.g. `showShadDialog` using `ShadButton.destructive()`). Make sure to also add the localization strings.
