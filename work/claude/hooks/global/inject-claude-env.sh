#!/bin/bash
# Hook: Inject CLAUDE_CODE=1 env var for git commit commands
# Runs as PreToolUse hook on Bash tool
# Reads hook input JSON from stdin, detects git commit, prepends env var

set -euo pipefail

input=$(cat)
command=$(echo "${input}" | jq -r '.tool_input.command // empty')

if [[ -n "${command}" ]]; then
  # Check if this is a git commit command (handles both "git commit" and "git -- commit")
  if [[ "${command}" =~ git[[:space:]]+(commit|--).* ]]; then
    jq -n --arg cmd "export CLAUDE_CODE=1; ${command}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        updatedInput: { command: $cmd }
      }
    }'
  fi
fi
