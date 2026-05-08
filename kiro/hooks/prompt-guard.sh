#!/usr/bin/env bash
# Prompt guard — cost control + reckless scope detection
set -euo pipefail

input=$(cat)
prompt=$(echo "${input}" | jq -r '.prompt // empty')
prompt_len=${#prompt}

# Block giant pastes
if ((prompt_len > 8000)); then
  echo "Prompt too large (${prompt_len} chars). Reference file paths instead of pasting content." >&2
  exit 2
fi

# Block genuinely reckless broad scope
if echo "${prompt}" | grep -qiE \
  '^(summarize|explain|read|analyze) (the )?(entire |whole |full |all (of )?)?(codebase|repo|project|everything)\.?$'; then
  echo "Scope too broad. Target a specific module, file, or concern." >&2
  exit 2
fi

# Inject cost reminder for bulk ops — no block
if echo "${prompt}" | grep -qiE '(read|analyze|review).*(repo|all files|every file|[0-9]+ files)'; then
  echo "[Cost note: bulk read in progress. Glob first, read selectively.]"
fi

exit 0
