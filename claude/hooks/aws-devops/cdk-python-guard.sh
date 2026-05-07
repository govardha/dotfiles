#!/usr/bin/env bash
# AWS DevOps CDK Python guard — IAM, removal policy, hardcoded IDs
set -euo pipefail

input=$(cat)
file=$(echo "${input}" | jq -r '.tool_input.file_path // empty')

[[ "${file}" == *.py ]] || exit 0

content=$(echo "${input}" | jq -r '.tool_input.new_content // empty')

[[ -z "${content}" ]] && exit 0

# Only apply to CDK files
echo "${content}" | grep -qE '(aws_cdk|constructs|Stack|Construct)' || exit 0

# ── IAM wildcard action or resource ──────────────────────────────────────────
if echo "${content}" | grep -qE 'actions=\["\*"\]|resources=\["\*"\]'; then
  echo "BLOCKED: Wildcard IAM action or resource in ${file}." >&2
  echo "Scope permissions to minimum required." >&2
  exit 2
fi

# ── Stateful resources missing removal_policy ─────────────────────────────────
for resource in 'Bucket(' 'DatabaseInstance(' 'Table(' 'FileSystem(' 'CfnDBCluster('; do
  if echo "${content}" | grep -qF "${resource}"; then
    if ! echo "${content}" | grep -q 'removal_policy'; then
      echo "BLOCKED: Stateful resource '${resource}' in ${file} missing removal_policy." >&2
      echo "Add RemovalPolicy.RETAIN for prod stacks." >&2
      exit 2
    fi
  fi
done

# ── Hardcoded AWS account ID ──────────────────────────────────────────────────
if echo "${content}" | grep -qE '"[0-9]{12}"'; then
  echo "BLOCKED: Hardcoded AWS account ID in ${file}." >&2
  echo "Use CDK_DEFAULT_ACCOUNT or context variables." >&2
  exit 2
fi

# ── Hardcoded region strings ──────────────────────────────────────────────────
if echo "${content}" | grep -qE '"(us|eu|ap|sa|ca|me|af)-(east|west|north|south|central)-[0-9]"'; then
  echo "WARN: Hardcoded region in ${file}. Use CDK_DEFAULT_REGION or Stack env." >&2
  exit 2
fi

exit 0
