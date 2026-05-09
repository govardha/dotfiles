#!/usr/bin/env bash
# Unified bash guard — sysops + k8s + aws checks
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# ── Runaway loops ─────────────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'while true|yes \|'; then
  echo "Unbounded loop detected. Add explicit exit condition or iteration cap." >&2
  exit 2
fi

# ── Mass delete in shared dirs ────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'rm -rf.*(\/opt|\/var|\/srv|\/data)'; then
  echo "Mass delete targeting shared path. Scope to explicit subdirectory." >&2
  exit 2
fi

# ── Literal credentials ──────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '(password|secret|token|api_key)\s*=\s*["'"'"'][^$]'; then
  echo "Literal credential in command. Use environment variable or secrets file." >&2
  exit 2
fi

# ── Literal AWS keys ─────────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'AKIA[0-9A-Z]{16}|aws_secret_access_key\s*='; then
  echo "BLOCKED: Literal AWS credentials in command. Use AWS_PROFILE or instance role." >&2
  exit 2
fi

# ── cdk deploy/destroy ───────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^cdk deploy'; then
  echo "BLOCKED: Run 'cdk diff' before 'cdk deploy'. Deploy manually after review." >&2
  exit 2
fi

if echo "${cmd}" | grep -qE '^cdk destroy'; then
  echo "BLOCKED: cdk destroy not permitted. Execute manually." >&2
  exit 2
fi

# ── aws s3 delete without --dryrun ───────────────────────────────────────────
if echo "${cmd}" | grep -qE '^aws s3(api)? (rm|delete)'; then
  if ! echo "${cmd}" | grep -q '\-\-dryrun'; then
    echo "BLOCKED: aws s3 delete requires --dryrun first." >&2
    exit 2
  fi
fi

# ── AWS prod account check ───────────────────────────────────────────────────
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

# ── kubectl mutating ops require --dry-run ───────────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl (apply|delete|patch|replace|scale|rollout restart)'; then
  if ! echo "${cmd}" | grep -q '\-\-dry-run'; then
    echo "BLOCKED: kubectl mutating op requires --dry-run=client first." >&2
    exit 2
  fi
fi

# ── kubectl prod context block ───────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl'; then
  current_ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  if echo "${current_ctx}" | grep -qiE '(prod|prd|production)'; then
    echo "BLOCKED: kubectl context is '${current_ctx}' (prod)." >&2
    echo "Switch context: kubectl config use-context <staging-context>" >&2
    exit 2
  fi
fi

# ── helm without dry-run ─────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^helm (upgrade|install|uninstall)'; then
  if ! echo "${cmd}" | grep -qE '(--dry-run|diff)'; then
    echo "BLOCKED: helm upgrade/install requires --dry-run or 'helm diff' first." >&2
    exit 2
  fi
fi

# ── argocd prod sync ─────────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'argocd app sync.*(prod|prd)'; then
  echo "BLOCKED: Direct ArgoCD sync to prod not permitted. Use gitops PR flow." >&2
  exit 2
fi

# ── cron reminder (no block) ─────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'crontab'; then
  echo "[Reminder: cron job output must redirect to logger or a log-rotated path]"
fi

exit 0
