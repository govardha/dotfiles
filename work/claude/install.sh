#!/usr/bin/env bash
# Usage: bash /path/to/claude/install.sh [--dry-run] [profile]
# Profiles: infra-ops | sysops | k8s-devops | aws-devops | java-dev
# No profile = base only (prompt guard + audit)
# Idempotent: safe to re-run. Backs up changed files with timestamps.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
AGENTS_DIR="${CLAUDE_DIR}/agents"
MEMORY_DIR="${CLAUDE_DIR}/memory"
BACKUP_DIR="${HOME}/.claude/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TIMESTAMP_PATH="${BACKUP_DIR}/${TIMESTAMP}"

DRY_RUN=false
PROFILE="base"

# Parse arguments
for arg in "$@"; do
  if [[ "${arg}" == "--dry-run" ]]; then
    DRY_RUN=true
  else
    PROFILE="${arg}"
  fi
done

# Counters for reporting
UPDATED=0
BACKED_UP=0
UNCHANGED=0
TOTAL=0

# ── Helper functions ──────────────────────────────────────────────────────────
file_hash() {
  [[ -f "$1" ]] && md5sum "$1" 2>/dev/null | awk '{print $1}' || echo ""
}

should_update() {
  local src="$1"
  local dst="$2"
  [[ ! -f "${dst}" ]] && return 0
  [[ "$(file_hash "${src}")" != "$(file_hash "${dst}")" ]]
}

backup_file() {
  local src="$1"
  local dst="$2"
  [[ ! -f "${dst}" ]] && return 0
  mkdir -p "${TIMESTAMP_PATH}"
  cp "${dst}" "${TIMESTAMP_PATH}/$(basename "${dst}")"
}

safe_copy() {
  local src="$1"
  local dst="$2"
  TOTAL=$((TOTAL + 1))

  if ! should_update "${src}" "${dst}"; then
    UNCHANGED=$((UNCHANGED + 1))
    return 0
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    UPDATED=$((UPDATED + 1))
    return 0
  fi

  if [[ -f "${dst}" ]]; then
    backup_file "${src}" "${dst}"
    BACKED_UP=$((BACKED_UP + 1))
  fi

  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
  chmod +x "${dst}" 2>/dev/null || true
  UPDATED=$((UPDATED + 1))
}

configure_gitconfig_local() {
  local gitconfig_local="${HOME}/.gitconfig_local"
  local changed=0

  # Ensure ~/.gitconfig includes ~/.gitconfig_local
  if ! git config --global --get-all include.path 2>/dev/null | grep -qF "${gitconfig_local}"; then
    if [[ "${DRY_RUN}" == true ]]; then
      echo "  would add [include] path = ${gitconfig_local} to ${HOME}/.gitconfig"
    else
      git config --global --add include.path "${gitconfig_local}"
      echo "  ✓ added [include] path = ${gitconfig_local} to ${HOME}/.gitconfig"
    fi
    changed=$((changed + 1))
  fi

  _set_git_cfg() {
    local key="$1" value="$2"
    local current
    current=$(git config --file "${gitconfig_local}" "${key}" 2>/dev/null || echo "")
    if [[ "${current}" == "${value}" ]]; then
      return 0
    fi
    if [[ "${DRY_RUN}" == true ]]; then
      echo "  would set ${key} = ${value}"
    else
      git config --file "${gitconfig_local}" "${key}" "${value}"
      echo "  ✓ set ${key} = ${value}"
    fi
    changed=$((changed + 1))
  }

  _set_git_cfg "user.name" "${USER}"
  _set_git_cfg "user.email" "${USER}@MIAXGlobal.com"
  _set_git_cfg "core.hooksPath" "${HOME}/.git-hooks"

  # GitHub: blank helper first clears any inherited chain, then the real helper.
  # Check both entries are present in the right order.
  local gh_helpers
  gh_helpers=$(git config --file "${gitconfig_local}" --get-all credential.https://github.com.helper 2>/dev/null | tr '\n' '|' || echo "")
  if [[ "${gh_helpers}" != "|!gh auth git-credential|" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
      echo "  would set credential.https://github.com.helper = (blank + !gh auth git-credential)"
    else
      git config --file "${gitconfig_local}" --unset-all credential.https://github.com.helper 2>/dev/null || true
      git config --file "${gitconfig_local}" credential.https://github.com.helper ""
      git config --file "${gitconfig_local}" --add credential.https://github.com.helper "!gh auth git-credential"
      echo "  ✓ set credential.https://github.com.helper = (blank + !gh auth git-credential)"
    fi
    changed=$((changed + 1))
  fi

  # Migrate: remove old URL-scoped Bitbucket helper if present
  if git config --file "${gitconfig_local}" --get credential.https://devtools.miamiholdings.corp.helper &>/dev/null; then
    if [[ "${DRY_RUN}" == true ]]; then
      echo "  would remove credential.https://devtools.miamiholdings.corp.helper (superseded by global helper)"
    else
      git config --file "${gitconfig_local}" --unset credential.https://devtools.miamiholdings.corp.helper
      echo "  ✓ removed credential.https://devtools.miamiholdings.corp.helper"
    fi
    changed=$((changed + 1))
  fi

  # Bitbucket: global fallback credential helper (handles all non-GitHub hosts)
  _set_git_cfg "credential.helper" "!${HOME}/.claude/scripts/git-credential-bitbucket"

  if [[ ${changed} -eq 0 ]]; then
    echo "✓ git identity and credential helpers already configured"
  elif [[ "${DRY_RUN}" == true ]]; then
    echo "✓ DRY RUN: ${changed} git config setting(s) would be written to ${gitconfig_local}"
  else
    echo "✓ Configured ${changed} git setting(s) in ${gitconfig_local}"
  fi
}

# ── Create base directories ───────────────────────────────────────────────────
mkdir -p "${HOOKS_DIR}" "${AGENTS_DIR}" "${MEMORY_DIR}"

# ── Configure git identity and credential helpers ─────────────────────────────
echo "Configuring git identity and credential helpers..."
configure_gitconfig_local
GIT_HOOKS_DIR="${HOME}/.git-hooks"
mkdir -p "${GIT_HOOKS_DIR}"
safe_copy "${DOTFILES_DIR}/hooks/global/prepare-commit-msg" "${GIT_HOOKS_DIR}/prepare-commit-msg"

# ── Copy Claude helper scripts ───────────────────────────────────────────────
safe_copy "${DOTFILES_DIR}/.claude-commit" "${CLAUDE_DIR}/.claude-commit"
safe_copy "${DOTFILES_DIR}/.claude-pr" "${CLAUDE_DIR}/.claude-pr"

# ── Copy helper scripts ─────────────────────────────────────────────────────────
SCRIPTS_DIR="${CLAUDE_DIR}/scripts"
mkdir -p "${SCRIPTS_DIR}"
safe_copy "${DOTFILES_DIR}/scripts/statusline.py" "${SCRIPTS_DIR}/statusline.py"
safe_copy "${DOTFILES_DIR}/scripts/git-credential-bitbucket" "${SCRIPTS_DIR}/git-credential-bitbucket"

# ── Install global CLAUDE.md ──────────────────────────────────────────────────
safe_copy "${DOTFILES_DIR}/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"

# ── Copy team baseline memories (non-destructive: new files only) ────────────
if [[ -d "${DOTFILES_DIR}/memory" ]]; then
  for memory in "${DOTFILES_DIR}"/memory/*.md; do
    [[ -f "${memory}" ]] || continue
    safe_copy "${memory}" "${MEMORY_DIR}/$(basename "${memory}")"
  done
fi

# ── Common hooks (always installed) ──────────────────────────────────────────
for hook in audit.sh prompt-guard.sh session-start.sh branch-guard.sh git-guard.sh bash-guard.sh detect-vcs.sh bkt-wrapper; do
  [[ -f "${DOTFILES_DIR}/hooks/common/${hook}" ]] || continue
  safe_copy "${DOTFILES_DIR}/hooks/common/${hook}" "${HOOKS_DIR}/${hook}"
done

# ── Global hooks (always installed) ──────────────────────────────────────────
mkdir -p "${HOOKS_DIR}/global"
safe_copy "${DOTFILES_DIR}/hooks/global/inject-claude-env.sh" "${HOOKS_DIR}/global/inject-claude-env.sh"
safe_copy "${DOTFILES_DIR}/hooks/global/pr-footer-guard.sh" "${HOOKS_DIR}/global/pr-footer-guard.sh"

# ── Skills (bkt for Bitbucket operations) ───────────────────────────────────────
if [[ -d "${DOTFILES_DIR}/skills/bkt" ]]; then
  mkdir -p "${CLAUDE_DIR}/skills"
  if [[ "${DRY_RUN}" != true ]]; then
    cp -r "${DOTFILES_DIR}/skills/bkt" "${CLAUDE_DIR}/skills/"
    chmod +x "${CLAUDE_DIR}/skills/bkt"/* 2>/dev/null || true
  fi
fi

# ── Shell secrets for Bitbucket credentials ──────────────────────────────────
SECRETS_FILE="${HOME}/.config/shell/secrets"
if [[ ! -f "${SECRETS_FILE}" ]]; then
  if [[ "${DRY_RUN}" != true ]]; then
    mkdir -p "${HOME}/.config/shell"
    cat >"${SECRETS_FILE}" <<'SECRETS'
# Bitbucket on-prem credentials for bkt CLI
export BKT_HOST="https://devtools.miamiholdings.corp/bitbucket"
export BKT_TOKEN="*** REPLACE WITH YOUR PERSONAL ACCESS TOKEN ***"

# Get your token: Bitbucket Settings → Personal Access Tokens
# Required scopes: repository, pullrequest:read, pullrequest:write
SECRETS
    chmod 600 "${SECRETS_FILE}"
    echo "✓ Created ${SECRETS_FILE}"
    echo "  ⚠ Update BKT_TOKEN with your personal access token"
  fi
fi

# ── Profile-specific hooks + settings ────────────────────────────────────────
case "${PROFILE}" in
  infra-ops)
    safe_copy "${DOTFILES_DIR}/hooks/infra-ops/write-guard.sh" "${HOOKS_DIR}/write-guard.sh"
    safe_copy "${DOTFILES_DIR}/hooks/k8s-devops/yaml-guard.sh" "${HOOKS_DIR}/yaml-guard.sh"
    safe_copy "${DOTFILES_DIR}/hooks/aws-devops/cdk-python-guard.sh" "${HOOKS_DIR}/cdk-python-guard.sh"
    safe_copy "${DOTFILES_DIR}/settings/infra-ops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/infra-ops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/infra-ops.md" "${AGENTS_DIR}/infra-ops.md"
    ;;
  sysops)
    safe_copy "${DOTFILES_DIR}/hooks/sysops/write-guard.sh" "${HOOKS_DIR}/write-guard.sh"
    safe_copy "${DOTFILES_DIR}/settings/sysops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/sysops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/sysops.md" "${AGENTS_DIR}/sysops.md"
    ;;
  k8s-devops)
    safe_copy "${DOTFILES_DIR}/hooks/k8s-devops/yaml-guard.sh" "${HOOKS_DIR}/yaml-guard.sh"
    safe_copy "${DOTFILES_DIR}/settings/k8s-devops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/k8s-devops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/k8s-devops.md" "${AGENTS_DIR}/k8s-devops.md"
    ;;
  aws-devops)
    safe_copy "${DOTFILES_DIR}/hooks/aws-devops/cdk-python-guard.sh" "${HOOKS_DIR}/cdk-python-guard.sh"
    safe_copy "${DOTFILES_DIR}/settings/aws-devops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/aws-devops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/aws-devops.md" "${AGENTS_DIR}/aws-devops.md"
    ;;
  java-dev)
    safe_copy "${DOTFILES_DIR}/settings/base-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/java-dev.md" ]] && safe_copy "${DOTFILES_DIR}/agents/java-dev.md" "${AGENTS_DIR}/java-dev.md"
    ;;
  base)
    safe_copy "${DOTFILES_DIR}/settings/base-settings.json" "${CLAUDE_DIR}/settings.json"
    ;;
  *)
    echo "Unknown profile: ${PROFILE}" >&2
    echo "Valid: infra-ops | sysops | k8s-devops | aws-devops | java-dev | base" >&2
    exit 1
    ;;
esac

# ── Record profile and timestamp in metadata file ────────────────────────────
if [[ "${DRY_RUN}" != true ]]; then
  cat >"${CLAUDE_DIR}/.profile" <<META
profile=${PROFILE}
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
META
fi

# ── Print summary report ──────────────────────────────────────────────────────
if [[ "${DRY_RUN}" == true ]]; then
  echo "✓ DRY RUN: Install profile '${PROFILE}' to ${CLAUDE_DIR}"
  echo "  Would update: ${UPDATED} files"
  if [[ ${BACKED_UP} -gt 0 ]]; then
    echo "  Would back up: ${BACKED_UP} files → ${TIMESTAMP_PATH}/"
  fi
  echo "  Unchanged: ${UNCHANGED} files"
  echo "  Total: ${TOTAL} files checked"
else
  if [[ ${UPDATED} -eq 0 && ${BACKED_UP} -eq 0 ]]; then
    echo "✓ All files current. Profile '${PROFILE}' → ${CLAUDE_DIR}"
    echo "  Unchanged: ${UNCHANGED} files"
  else
    echo "✓ Installed profile '${PROFILE}' → ${CLAUDE_DIR}"
    echo "  Updated: ${UPDATED} files"
    if [[ ${BACKED_UP} -gt 0 ]]; then
      echo "  Backed up: ${BACKED_UP} files → ${TIMESTAMP_PATH}/"
    fi
    echo "  Unchanged: ${UNCHANGED} files"
  fi
fi
