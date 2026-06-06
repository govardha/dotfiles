---
name: Enterprise constraints
description: Hard boundaries—what Claude must never do in this org
type: feedback
---

## Never commit directly to main/master

All changes go through feature branches (`feature/*`, `fix/*`, `bugfix/*`) with pull request review. This applies to everyone, especially new users learning the tool.

**Why:** Prevents accidents, ensures code review, maintains clean history.

**How to apply:** If you see `git push origin main` or `git commit --amend && git push --force`, stop and redirect to feature branch workflow.

## Never commit secrets or sensitive data

.env files, API keys, credentials, tokens, passwords, PII, or any non-public information must never be staged or committed.

**Why:** Secrets in git history are nearly impossible to fully remove; they become a permanent liability even if deleted later.

**How to apply:** Before staging files, verify:
- No `.env`, `.secrets`, `credentials.json`, or similar files
- No hardcoded keys/tokens in code
- No database backups, exports, or dumps
- Warn the user if they try to stage sensitive files; refuse if they insist without strong justification
