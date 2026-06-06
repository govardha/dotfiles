#!/usr/bin/env bash
# k8s DevOps bash guard — kubectl/helm/argo discipline
set -euo pipefail

input=$(cat)
cmd=$(echo "${input}" | jq -r '.tool_input.command // empty')

[[ -z "${cmd}" ]] && exit 0

# ── kubectl mutating ops require --dry-run first ──────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl (apply|delete|patch|replace|scale|rollout restart)'; then
  if ! echo "${cmd}" | grep -q '\-\-dry-run'; then
    echo "BLOCKED: kubectl mutating op requires --dry-run=client first." >&2
    echo "Confirm output then re-run without --dry-run." >&2
    exit 2
  fi
fi

# ── Block kubectl against prod context ────────────────────────────────────────
if echo "${cmd}" | grep -qE '^kubectl'; then
  current_ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  if echo "${current_ctx}" | grep -qiE '(prod|prd|production)'; then
    echo "BLOCKED: kubectl context is '${current_ctx}' (prod)." >&2
    echo "Switch context: kubectl config use-context <staging-context>" >&2
    exit 2
  fi
fi

# ── helm upgrade/install requires --dry-run ───────────────────────────────────
if echo "${cmd}" | grep -qE '^helm (upgrade|install|uninstall)'; then
  if ! echo "${cmd}" | grep -qE '(--dry-run|diff)'; then
    echo "BLOCKED: helm upgrade/install requires --dry-run or 'helm diff' first." >&2
    exit 2
  fi
fi

# ── ArgoCD direct prod sync blocked ──────────────────────────────────────────
if echo "${cmd}" | grep -qE 'argocd app sync.*(prod|prd)'; then
  echo "BLOCKED: Direct ArgoCD sync to prod not permitted via Claude." >&2
  echo "Merge to main and let ArgoCD auto-sync via gitops flow." >&2
  exit 2
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
