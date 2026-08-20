#!/usr/bin/env bash
# Guard: Detect bare PR creation commands and remind users to use wrapper
#
# This is informational only (exit 0) — it helps users know about the
# automatic footer injection feature without blocking their workflow.

TOOL_NAME="$1"
COMMAND="$2"

# Only check PR creation commands
if [[ ! "$COMMAND" =~ (bkt|gh)\ pr\ create ]]; then
  exit 0
fi

# If description/body is already provided, user is probably intentional
if [[ "$COMMAND" =~ (--description|--body) ]]; then
  exit 0
fi

# Provide helpful context
cat << 'MSG'

💡 Tip: Use the 'claude-pr', 'bkt-pr', or 'gh-pr' alias for automatic
   Claude Code attribution footer injection.

   Examples:
     claude-pr --title "Fix bug" --target main
     bkt-pr --title "Add feature" --target main
     gh-pr --title "Update docs" --target main

   These aliases ensure your PR includes the enterprise attribution:
   "🤖 Generated with [Claude Code](https://claude.com/claude-code)"

MSG

exit 0
