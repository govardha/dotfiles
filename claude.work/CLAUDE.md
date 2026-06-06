# Coding Style Rules

# CRITICAL: Git Workflow (ALWAYS FOLLOW)

- Never commit or push directly to main/master
- All changes on feature or bugfix branches (e.g. `feature/add-xyz`, `fix/broken-thing`)
- Merge to main only via pull request
- Atomic commits — one logical change per commit
- Commit messages: imperative mood, under 72 chars
- All commits include `Co-Authored-By: Claude <noreply@anthropic.com>` footer

## Python

- Formatter: ruff (Black-compatible defaults)
- Line length: 88 characters max
- Indentation: 4 spaces
- Quotes: double quotes
- Trailing commas on multi-line structures
- Imports: sorted with ruff's isort (standard library, third-party, local — separated by blank lines)
- f-strings preferred over .format() or %

## Shell (bash/sh)

- Indentation: 2 spaces
- Indent switch case bodies
- Use `[[` over `[` in bash
- Quote variables: `"${var}"` not `$var`
- `set -euo pipefail` on every script

## YAML / JSON

- Indentation: 2 spaces
- No trailing whitespace
- Prettier-compatible formatting

## Lua

- Indentation: 2 spaces (StyLua defaults)

## Bitbucket vs GitHub

- On-prem Bitbucket repos: use `bkt`
- GitHub repos: use `gh`
- Dual remote repos: check repo-level CLAUDE.md for source of truth

## Tooling

- bkt binary: /apps/ops/bin/bkt (wrapper, auto-detects project/repo)
- gh binary: standard PATH

## General

- Default indentation: 2 spaces
- No trailing whitespace
- Files end with a single newline
- UTF-8 encoding

### How Claude Co-Author Footer Works

Two complementary mechanisms distinguish Claude commits from human commits:

1. **Git Hook** (`~/.git-hooks/prepare-commit-msg`)
   - Adds the Claude footer when `CLAUDE_CODE=1` env var is set
   - Humans commit normally without the env var (no footer)

2. **Claude Code Hook** (`~/.claude/hooks/global/inject-claude-env.sh`)
   - Automatically runs before Bash tool executes git commands
   - Detects `git commit` commands and auto-injects `CLAUDE_CODE=1`
   - Transparent — no manual env var or special script needed

**Result:**

- **Claude commits** are auto-detected and get footer automatically
- **Human commits** use normal `git commit` (no footer)

No action needed — the hook fires automatically when Claude runs git commit commands.
