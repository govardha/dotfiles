#!/usr/bin/env bash
# Hook: Remind agent to include Co-Authored-By footer in gh pr create
# Kiro hooks cannot mutate inputs — prints context reminder instead
set -euo pipefail

input=$(cat /dev/stdin 2>/dev/null || echo "")

# Only act on gh pr create
if ! echo "${input}" | grep -qE "gh pr create"; then
  exit 0
fi

# If footer already present, no action needed
if echo "${input}" | grep -qF "Co-Authored-By: Kiro"; then
  exit 0
fi

echo "BLOCKED: PR body must include: Co-Authored-By: Kiro <noreply@kiro.dev>" >&2
exit 2
