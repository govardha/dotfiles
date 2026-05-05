# Coding Style Rules

Follow these formatting rules for all code you write or modify.

## Python
- Formatter: ruff (Black-compatible defaults)
- Line length: 88 characters max
- Indentation: 4 spaces
- Quotes: double quotes (not single)
- Trailing commas on multi-line structures
- Imports: sorted with ruff's isort (standard library, third-party, local — separated by blank lines)
- f-strings preferred over .format() or %

## Shell (bash/sh)
- Indentation: 2 spaces
- Indent switch case bodies (`-ci` flag behavior)
- Use `[[` over `[` in bash
- Quote variables: `"${var}"` not `$var`

## YAML
- Indentation: 2 spaces
- No trailing whitespace
- Prettier-compatible formatting

## JSON
- Indentation: 2 spaces
- Prettier-compatible formatting

## Lua
- Indentation: 2 spaces (StyLua defaults)

## General
- Default indentation: 2 spaces (matches editor tabstop/shiftwidth)
- No trailing whitespace
- Files end with a single newline
- UTF-8 encoding

## Git Workflow
- Never commit or push directly to main/master
- All changes go on a feature or bugfix branch (e.g. `feature/add-xyz`, `fix/broken-thing`)
- Merge to main/master only via pull request
- Keep commits atomic — one logical change per commit
- Write concise commit messages: imperative mood, under 72 chars
