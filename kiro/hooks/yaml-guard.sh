#!/usr/bin/env bash
# YAML guard — k8s manifest quality enforcement
set -euo pipefail

input=$(cat)
file=$(echo "${input}" | jq -r '.tool_input.file_path // .tool_input.path // empty')

[[ "${file}" =~ \.(yaml|yml)$ ]] || exit 0

content=$(echo "${input}" | jq -r '.tool_input.file_text // .tool_input.new_content // empty')

[[ -z "${content}" ]] && exit 0

# ── latest image tag ─────────────────────────────────────────────────────────
if echo "${content}" | grep -qE 'image:.*:latest'; then
  echo "BLOCKED: 'latest' image tag in ${file}. Use explicit semver or digest." >&2
  exit 2
fi

# ── resource limits required on workload types ───────────────────────────────
if echo "${content}" | grep -qE '^kind: (Deployment|StatefulSet|DaemonSet)'; then
  if ! echo "${content}" | grep -q 'resources:'; then
    echo "BLOCKED: Workload manifest missing 'resources:' block in ${file}." >&2
    exit 2
  fi
fi

# ── explicit namespace required ──────────────────────────────────────────────
if echo "${content}" | grep -qE '^kind: (Deployment|Service|ConfigMap|Secret|Ingress|StatefulSet)'; then
  if ! echo "${content}" | grep -q 'namespace:'; then
    echo "BLOCKED: Manifest missing 'namespace:' in metadata in ${file}." >&2
    exit 2
  fi
fi

# ── prod namespace — hard stop ───────────────────────────────────────────────
if echo "${content}" | grep -qE 'namespace:\s*(prod|production|prd)'; then
  echo "BLOCKED: Prod namespace in ${file}. Route through gitops PR." >&2
  exit 2
fi

exit 0
