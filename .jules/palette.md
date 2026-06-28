## 2024-05-20 - [Avoid Automation Scripts for Localization]
**Learning:** Using temporary automation bash scripts (e.g. running 'sed' from a script file) to modify `.arb` localization files leaves execution artifacts in the workspace which will be flagged in code reviews as junk files.
**Action:** Use strict string replacement tools (like `replace_with_git_merge_diff`) or direct file modification commands (like direct `sed -i` calls) to safely modify `.arb` files without creating temporary executable scripts.
