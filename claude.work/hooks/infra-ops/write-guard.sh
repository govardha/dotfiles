#!/usr/bin/env bash
# Infra-ops write guard — allow git repos + sysops paths
set -euo pipefail

input=$(cat)
file=$(echo "${input}" | jq -r '.tool_input.file_path // empty')

[[ -z "${file}" ]] && exit 0

# Always allow writes inside a git repo (project work)
dir=$(dirname "${file}")
if git -C "${dir}" rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# Allowed write paths outside git repos
allowed_prefixes=(
  "/home/${USER}"
  "/apps/${USER}"
  "/apps/ops"
  "/tmp"
  "/var/tmp"
)

for prefix in "${allowed_prefixes[@]}"; do
  if [[ "${file}" == "${prefix}"* ]]; then
    exit 0
  fi
done

echo "Write to '${file}' outside allowed paths and not in a git repo." >&2
echo "Allowed: git repos, ${allowed_prefixes[*]}" >&2
exit 2
