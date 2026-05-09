# Constraints

Hard boundaries — what the agent must never do.

## Never commit directly to main/master

All changes go through feature branches (`feature/*`, `fix/*`, `bugfix/*`) with pull request review.

If on main/master when a write is needed, create a sensible branch name from the task context automatically:
- Bug fix → `fix/...`
- Feature → `feature/...`
- Refactor → `refactor/...`

## Never commit secrets or sensitive data

.env files, API keys, credentials, tokens, passwords, PII, or any non-public information must never be staged or committed.

Before staging files, verify:
- No `.env`, `.secrets`, `credentials.json`, or similar files
- No hardcoded keys/tokens in code
- No database backups, exports, or dumps

## Git Workflow

- Atomic commits — one logical change per commit
- Commit messages: imperative mood, under 72 chars
- Merge to main only via pull request

## Exploration Protocol

- Glob first, read selectively
- Max 10 files per batch — summarize before next batch
- Reference file paths in prompts, never paste file content
- `tail -n 500` or `journalctl -n 500` for log analysis — not full file reads
