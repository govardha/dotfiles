#!/usr/bin/env bash
# Infra-ops bash guard — combined sysops + k8s + aws checks
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# ── Sysops: runaway loops ─────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'while true|yes \|'; then
  echo "Unbounded loop detected. Add explicit exit condition or iteration cap." >&2
  exit 2
fi

# ── Sysops: mass delete in shared dirs ────────────────────────────────────────
if echo "${cmd}" | grep -qE 'rm -rf.*(\/opt|\/var|\/srv|\/data)'; then
  echo "Mass delete targeting shared path. Scope to explicit subdirectory." >&2
  exit 2
fi

# ── Sysops: literal credentials ──────────────────────────────────────────────
if echo "${cmd}" | grep -qE '(password|secret|token|api_key)\s*=\s*["'"'"'][^$]'; then
  echo "Literal credential in command. Use environment variable or secrets file." >&2
  exit 2
fi

# ── AWS: literal AWS keys ────────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'AKIA[0-9A-Z]{16}|aws_secret_access_key\s*='; then
  echo "BLOCKED: Literal AWS credentials in command. Use AWS_PROFILE or instance role." >&2
  exit 2
fi

# ── AWS: cdk deploy/destroy ──────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^cdk deploy'; then
  echo "BLOCKED: Run 'cdk diff' before 'cdk deploy'. Deploy manually after review." >&2
  exit 2
fi

if echo "${cmd}" | grep -qE '^cdk destroy'; then
  echo "BLOCKED: cdk destroy not permitted via Claude. Execute manually." >&2
  exit 2
fi

# ── AWS: s3 delete without --dryrun ──────────────────────────────────────────
if echo "${cmd}" | grep -qE '^aws s3(api)? (rm|delete)'; then
  if ! echo "${cmd}" | grep -q '\-\-dryrun'; then
    echo "BLOCKED: aws s3 delete requires --dryrun first." >&2
    exit 2
  fi
fi

# ── AWS: prod account check ──────────────────────────────────────────────────
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

# ── k8s: kubectl mutating ops require --dry-run ──────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl (apply|delete|patch|replace|scale|rollout restart)'; then
  if ! echo "${cmd}" | grep -q '\-\-dry-run'; then
    echo "BLOCKED: kubectl mutating op requires --dry-run=client first." >&2
    exit 2
  fi
fi

# ── k8s: prod context block ──────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl'; then
  current_ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  if echo "${current_ctx}" | grep -qiE '(prod|prd|production)'; then
    echo "BLOCKED: kubectl context is '${current_ctx}' (prod)." >&2
    echo "Switch context: kubectl config use-context <staging-context>" >&2
    exit 2
  fi
fi

# ── k8s: helm without dry-run ────────────────────────────────────────────────
if echo "${cmd}" | grep -qE '^helm (upgrade|install|uninstall)'; then
  if ! echo "${cmd}" | grep -qE '(--dry-run|diff)'; then
    echo "BLOCKED: helm upgrade/install requires --dry-run or 'helm diff' first." >&2
    exit 2
  fi
fi

# ── k8s: argocd prod sync ───────────────────────────────────────────────────
if echo "${cmd}" | grep -qE 'argocd app sync.*(prod|prd)'; then
  echo "BLOCKED: Direct ArgoCD sync to prod not permitted via Claude." >&2
  echo "Merge to main and let ArgoCD auto-sync via gitops flow." >&2
  exit 2
fi

# ── Sysops: cron reminder (no block) ─────────────────────────────────────────
if echo "${cmd}" | grep -qE 'crontab'; then
  echo "[Reminder: cron job output must redirect to logger or a log-rotated path]"
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
