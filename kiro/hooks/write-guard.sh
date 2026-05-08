#!/usr/bin/env bash
# Write guard — allow git repos + known safe paths
set -euo pipefail

input=$(cat)
file=$(echo "${input}" | jq -r '.tool_input.file_path // .tool_input.path // empty')

[[ -z "${file}" ]] && exit 0

# Always allow writes inside a git repo
dir=$(dirname "${file}")
if git -C "${dir}" rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# Allowed write paths outside git repos
allowed_prefixes=(
  "/home/${USER}"
  "/tmp"
  "/var/tmp"
  "/opt/scripts"
  "/opt/monitoring"
  "/opt/cronjobs"
)

for prefix in "${allowed_prefixes[@]}"; do
  if [[ "${file}" == "${prefix}"* ]]; then
    exit 0
  fi
done

echo "Write to '${file}' outside allowed paths and not in a git repo." >&2
echo "Allowed: git repos, ${allowed_prefixes[*]}" >&2
exit 2
