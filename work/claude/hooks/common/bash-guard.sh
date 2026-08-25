#!/bin/bash
# Common bash guard — universal checks applicable to all profiles
# Focus: runaway loops, mass deletes, literal credentials
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

exit 0
