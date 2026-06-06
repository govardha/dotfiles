#!/bin/bash
# Hook: Inject CLAUDE_CODE=1 env var for git commit commands
# Runs as PreToolUse hook on Bash tool
# Reads hook input JSON from stdin, detects git commit, prepends env var

set -euo pipefail

# Read stdin
input=$(cat)

# Extract command using sed (more robust for quoted strings)
# Match "command": "value" and capture the value
command=$(echo "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p' | head -1)

# Only proceed if we got a command
if [[ -n "$command" ]]; then
  # Check if this is a git commit command (handles both "git commit" and "git -- commit")
  if [[ "$command" =~ git[[:space:]]+(commit|--).* ]]; then
    # Prepend CLAUDE_CODE=1 and return modified input
    modified_command="CLAUDE_CODE=1 $command"

    # Escape the command for JSON
    escaped_cmd=$(printf '%s\n' "$modified_command" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\/' | tr -d '\n')

    # Output JSON with updatedInput
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
  fi
fi
