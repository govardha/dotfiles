#!/usr/bin/env bash
# AWS DevOps bash guard — CDK/AWS CLI discipline
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# ── cdk deploy without diff — always block ────────────────────────────────────
if echo "${cmd}" | grep -qE '^cdk deploy'; then
  echo "BLOCKED: Run 'cdk diff' before 'cdk deploy'." >&2
  echo "Confirm changeset, then deploy manually." >&2
  exit 2
fi

# ── cdk destroy — never via Claude ───────────────────────────────────────────
if echo "${cmd}" | grep -qE '^cdk destroy'; then
  echo "BLOCKED: cdk destroy not permitted via Claude. Execute manually." >&2
  exit 2
fi

# ── aws CLI against prod account ──────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^(cdk|aws) '; then
  current_acct=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
  prod_accounts="${PROD_ACCOUNT_IDS:-UNSET}"
  if [[ "${prod_accounts}" != "UNSET" ]]; then
    if echo "${prod_accounts}" | grep -qE "(^|\\|)${current_acct}(\\||$)"; then
      echo "BLOCKED: AWS session is prod account ${current_acct}." >&2
      echo "Switch profile: export AWS_PROFILE=<staging-profile>" >&2
      exit 2
    fi
  fi
fi

# ── aws s3 rm / s3api delete without --dryrun ────────────────────────────────
if echo "${cmd}" | grep -qE '^aws s3(api)? (rm|delete)'; then
  if ! echo "${cmd}" | grep -q '\-\-dryrun'; then
    echo "BLOCKED: aws s3 delete requires --dryrun first." >&2
    exit 2
  fi
fi

# ── Literal AWS credentials in commands ───────────────────────────────────────
if echo "${cmd}" | grep -qE 'AKIA[0-9A-Z]{16}|aws_secret_access_key\s*='; then
  echo "BLOCKED: Literal AWS credentials in command. Use AWS_PROFILE or instance role." >&2
  exit 2
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
