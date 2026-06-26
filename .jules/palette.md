## 2024-05-18 - Added Tooltips to IconButtons
**Learning:** IconButtons used without tooltip limits accessibility, particularly for screen readers relying on ARIA/tooltip equivalents in Flutter. Adding a simple `tooltip` attribute directly into `IconButton` improves UX drastically and takes only a few lines.
**Action:** Always check `IconButton` for missing `tooltip` attributes when acting as Palette, especially in POS interaction screens.
