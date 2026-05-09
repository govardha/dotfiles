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
- `set -euo pipefail` on every script

## YAML
- Indentation: 2 spaces
- No trailing whitespace
- Prettier-compatible formatting

## JSON
- Indentation: 2 spaces
- Prettier-compatible formatting

## Lua
- Indentation: 2 spaces (StyLua defaults)

## Java
- Google Java Style Guide strictly
- Line length: 100 characters
- Constructor injection only — no @Autowired field injection
- Lombok allowed: @Data, @Builder, @Slf4j, @RequiredArgsConstructor

## General
- Default indentation: 2 spaces (matches editor tabstop/shiftwidth)
- No trailing whitespace
- Files end with a single newline
- UTF-8 encoding
