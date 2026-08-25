#!/bin/bash
# Detect git remote and determine whether to use gh (GitHub) or bkt (on-prem Bitbucket)
# Exit code 0 = allow, context is printed
# Exit code 2 = block (conflicting remotes), ask user to clarify via memory

set -euo pipefail

TOOL="${1:-}"
COMMAND="${2:-}"

# Only run for PR creation commands
if [[ "$COMMAND" != *"pr create"* && "$COMMAND" != *"pr "* ]]; then
  exit 0
fi

# Get all remotes and check origin
REMOTES=$(git remote -v 2>/dev/null || echo "")

# Count occurrences
GITHUB_COUNT=$(echo "$REMOTES" | grep -c "github.com" || true)
ONPREM_COUNT=$(echo "$REMOTES" | grep -c "devtools.miamiholdings.corp" || true)

# Determine which VCS
if [[ $GITHUB_COUNT -gt 0 && $ONPREM_COUNT -eq 0 ]]; then
  echo "🔵 VCS: GitHub detected → use 'gh pr create'"
  exit 0
elif [[ $ONPREM_COUNT -gt 0 && $GITHUB_COUNT -eq 0 ]]; then
  echo "🔵 VCS: On-prem Bitbucket detected → use 'bkt pr create' (will source ~/.config/shell/secrets)"
  exit 0
elif [[ $GITHUB_COUNT -gt 0 && $ONPREM_COUNT -gt 0 ]]; then
  echo "🔴 ERROR: Multiple VCS remotes detected (GitHub + on-prem Bitbucket)"
  echo "This repo has both github.com and devtools.miamiholdings.corp remotes."
  echo "Please clarify which one to use by creating a memory entry:"
  echo ""
  echo "  Example: 'Remember: this repo uses on-prem Bitbucket for PRs'"
  echo ""
  exit 2
else
  echo "⚠️  No recognized remote found. Remotes: $REMOTES"
  exit 0
fi
