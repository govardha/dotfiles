#!/usr/bin/env bash
# Common prompt guard — cost control + reckless scope detection
set -euo pipefail
input=$(cat)
prompt=$(echo "${input}" | jq -r '.prompt // empty')
prompt_len=${#prompt}

# Task-notifications are system-generated delivery of a background subagent's
# result — Claude Code writes the full output to <output-file> on disk and
# resubmits a notification as the next prompt. This isn't a human/agent
# choosing to paste content, and it can't be shortened by resubmitting (the
# framework regenerates the same notification), so exempt it from the size
# guard. Anchored near the start of the prompt so injected content elsewhere
# in a file can't spoof the exemption.
if [[ "${prompt}" =~ ^[[:space:]]{0,20}\<task-notification\> ]]; then
  exit 0
fi

# Block giant pastes — use file paths instead
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

# Inject cost reminder for deliberate bulk ops — no block
if echo "${prompt}" | grep -qiE '(read|analyze|review).*(repo|all files|every file|[0-9]+ files)'; then
  echo "[Cost note: bulk read in progress. Glob first, read selectively. Summarize per module before next batch.]"
fi
exit 0
