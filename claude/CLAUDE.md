# Coding Style Rules

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

## Git Workflow
- Never commit or push directly to main/master
- All changes on feature or bugfix branches (e.g. `feature/add-xyz`, `fix/broken-thing`)
- Merge to main only via pull request
- Atomic commits — one logical change per commit
- Commit messages: imperative mood, under 72 chars
