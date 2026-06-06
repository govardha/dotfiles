#!/usr/bin/env bash
# SysOps write guard — enforce allowed write paths (no sudo = limited blast radius)
set -euo pipefail

input=$(cat)
file=$(echo "${input}" | jq -r '.tool_input.file_path // empty')

[[ -z "${file}" ]] && exit 0

# Allowed write paths for no-sudo sysops
allowed_prefixes=(
  "/home/${USER}"
  "/apps/${USER}"
  "/apps/ops"
  "/tmp"
  "/var/tmp"
)

is_allowed=false
for prefix in "${allowed_prefixes[@]}"; do
  if [[ "${file}" == "${prefix}"* ]]; then
    is_allowed=true
    break
  fi
done

if [[ "${is_allowed}" == false ]]; then
  echo "Write to '${file}' outside sysops allowed paths." >&2
  echo "Allowed: ${allowed_prefixes[*]}" >&2
  exit 2
fi

exit 0
