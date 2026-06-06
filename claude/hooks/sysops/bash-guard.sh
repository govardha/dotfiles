#!/usr/bin/env bash
# SysOps bash guard — no sudo context, on-prem
# Focus: runaway loops, secrets in scripts, cron hygiene
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# Runaway loop patterns
if echo "${cmd}" | grep -qE 'while true|yes \|'; then
  echo "Unbounded loop detected. Add explicit exit condition or iteration cap." >&2
  exit 2
fi

# Mass delete inside shared dirs
if echo "${cmd}" | grep -qE 'rm -rf.*(\/opt|\/var|\/srv|\/data)'; then
  echo "Mass delete targeting shared path. Scope to explicit subdirectory." >&2
  exit 2
fi

# Literal credentials in commands
if echo "${cmd}" | grep -qE '(password|secret|token|api_key)\s*=\s*["'"'"'][^$]'; then
  echo "Literal credential in command. Use environment variable or secrets file." >&2
  exit 2
fi

# Cron reminder — inject context, no block
if echo "${cmd}" | grep -qE 'crontab'; then
  echo "[Reminder: cron job output must redirect to logger or a log-rotated path, not stdout]"
fi

# ── Git: Block add/commit on main/master ─────────────────────────────────────
if echo "${cmd}" | grep -qE '^git (add|commit)'; then
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
    echo "BLOCKED: git add/commit on ${current_branch}. Create a feature branch first." >&2
    exit 2
  fi
fi

# ── Git: Check for staged changes before push ────────────────────────────────
if echo "${cmd}" | grep -qE '^git push'; then
  if ! git diff --cached --quiet; then
    echo "BLOCKED: Staged changes exist but are not committed." >&2
    echo "Run 'git status' and commit your staged changes before pushing." >&2
    echo "" >&2
    git diff --cached --name-only >&2
    exit 2
  fi
fi

exit 0
