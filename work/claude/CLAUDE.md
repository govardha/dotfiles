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

## Bitbucket PR Creation (On-Prem)

If you're working on **on-prem Bitbucket** repos (devtools.miamiholdings.corp), Claude will create PRs using the `bkt` CLI.

### Setup (One-Time)

Create `~/.config/shell/secrets` with your Bitbucket credentials:

```bash
export BKT_HOST="https://devtools.miamiholdings.corp/bitbucket"
export BKT_TOKEN="your-personal-access-token"
```

**To get your token:**
1. Go to Bitbucket Settings → Personal Access Tokens
2. Create a new token with scopes: `repository`, `pullrequest:read`, `pullrequest:write`
3. Copy the token and add it to `~/.config/shell/secrets`

### How It Works

When Claude creates a PR on on-prem Bitbucket:
1. Sources `~/.config/shell/secrets` to load `BKT_HOST` and `BKT_TOKEN`
2. Runs `bkt pr create` with your repo's project and repo slug
3. Includes `Co-Authored-By: Claude` footer in PR body (required)

For GitHub repos, Claude uses `gh` CLI instead (no setup needed).

### Known Quirks

- **Personal repos require `--project "~alimberakis"`** — the tilde-prefixed username is the project key for user-owned repos (e.g. `bkt pr create --project "~alimberakis" --repo anthony ...`).
- **`bkt auth status` showing "No hosts configured" is misleading** — it reflects the interactive keyring, not env-var auth. `BKT_TOKEN` + `BKT_HOST` work correctly in headless/CLI mode regardless of what `auth status` reports.
