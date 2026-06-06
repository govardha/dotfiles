#!/bin/bash
# Hook: Append Co-Authored-By footer to PR descriptions (gh + bkt)
# PreToolUse hook on Bash tool — modifies command via updatedInput
set -euo pipefail

FOOTER="Co-Authored-By: Claude <noreply@anthropic.com>"

input=$(cat)
command=$(echo "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p' | head -1)

[[ -z "$command" ]] && exit 0

# Only act on gh pr create or bkt pr create
if ! echo "$command" | grep -qE "(gh|bkt) pr create"; then
  exit 0
fi

# Skip if footer already present
if echo "$command" | grep -qF "Co-Authored-By: Claude"; then
  exit 0
fi

# Append footer to --body if present, otherwise add --body with footer
if echo "$command" | grep -qE -- "--body"; then
  # Append footer to existing --body value (handle both quoted forms)
  modified_command=$(echo "$command" | sed -E "s/(--body ['\"]?)([^'\"]*)/\1\2\n\n${FOOTER}/")
else
  # Add --body flag with just the footer
  modified_command="$command --body \"${FOOTER}\""
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "updatedInput": {
      "command": "$modified_command"
    }
  }
}
EOF
