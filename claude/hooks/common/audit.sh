#!/usr/bin/env bash
# Async audit log — all teams. Fires PostToolUse.
AUDIT_LOG="${AUDIT_LOG:-${HOME}/.claude/logs/audit.jsonl}"
mkdir -p "$(dirname "${AUDIT_LOG}")"

input=$(cat)

echo "${input}" | jq -c \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg user "${USER}" \
  --arg host "$(hostname -s)" \
  '{
    ts: $ts,
    user: $user,
    host: $host,
    event: .hook_event_name,
    tool: .tool_name,
    target: (.tool_input.command // .tool_input.file_path // null)
  }' >>"${AUDIT_LOG}" 2>/dev/null

exit 0
