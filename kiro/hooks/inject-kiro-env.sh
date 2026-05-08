#!/usr/bin/env bash
# Hook: Inject KIRO_CLI=1 env var for git commit commands
# Runs as PreToolUse hook on execute_bash — detects git commit, prepends env var
set -euo pipefail

input=$(cat)
command=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -n "${command}" ]] || exit 0

if [[ "${command}" =~ git[[:space:]]+(commit|--).* ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "updatedInput": {
      "command": "KIRO_CLI=1 ${command}"
    }
  }
}
EOF
fi

exit 0
