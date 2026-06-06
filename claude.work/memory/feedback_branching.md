---
name: Auto-generate branch names
description: When branch-guard hook blocks, automatically create sensible branch without prompting user
type: feedback
---

When the branch-guard hook blocks a write to main/master, generate a sensible branch name from the user's request and create it automatically. No prompts needed.

**Why:** Minimal friction. The user prefers efficiency over choice paralysis — they want me to move fast and just pick a reasonable branch name.

**How to apply:** Parse the user's request (bug fix → `bug/...`, feature → `feature/...`, refactor → `refactor/...`) and derive a name from the key details. Create the branch and proceed. If the branch name is ambiguous or unclear, then ask.
