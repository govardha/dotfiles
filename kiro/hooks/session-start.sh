#!/usr/bin/env bash
# Session context injection — fires on agentSpawn
hostname=$(hostname -s)
env_type="unknown"

if echo "${hostname}" | grep -qiE '(prod|prd)'; then
  env_type="PRODUCTION"
elif echo "${hostname}" | grep -qiE '(stg|staging)'; then
  env_type="STAGING"
elif echo "${hostname}" | grep -qiE '(dev|local)'; then
  env_type="DEV"
fi

cat <<EOF
[Session context]
Host: ${hostname}
Environment: ${env_type}
User: ${USER}
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)

Active rules:
- Dry-run before any bulk operation
- No prod targets without staging confirmation first
- All destructive commands require explicit scope restatement
EOF

exit 0
