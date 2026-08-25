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

# Block if footer is missing — agent must include it
# Note: updatedInput mutation was removed as unreliable (sed on JSON).
# exit 2 is the standard Claude Code hook blocking mechanism.
echo "BLOCKED: PR body must include: ${FOOTER}" >&2
exit 2
