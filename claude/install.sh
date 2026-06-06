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

# ── Create base directories ───────────────────────────────────────────────────
mkdir -p "${HOOKS_DIR}" "${AGENTS_DIR}" "${MEMORY_DIR}"

# ── Set up global git hooks (Claude commits get footer, humans don't) ────────
EXISTING_HOOKS_PATH=$(git config --global core.hooksPath 2>/dev/null || echo "")

if [[ -n "${EXISTING_HOOKS_PATH}" ]]; then
  GIT_HOOKS_DIR="${EXISTING_HOOKS_PATH}"
else
  GIT_HOOKS_DIR="${HOME}/.git-hooks"
  if [[ "${DRY_RUN}" != true ]]; then
    git config --global core.hooksPath "${GIT_HOOKS_DIR}"
  fi
fi

mkdir -p "${GIT_HOOKS_DIR}"
safe_copy "${DOTFILES_DIR}/hooks/global/prepare-commit-msg" "${GIT_HOOKS_DIR}/prepare-commit-msg"

# ── Copy Claude commit helper script ─────────────────────────────────────────
safe_copy "${DOTFILES_DIR}/.claude-commit" "${CLAUDE_DIR}/.claude-commit"

# ── Install global CLAUDE.md ──────────────────────────────────────────────────
safe_copy "${DOTFILES_DIR}/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"

# ── Copy skills directory (applicable to all profiles) ──────────────────────
if [[ -d "${DOTFILES_DIR}/skills" ]]; then
  mkdir -p "${CLAUDE_DIR}/skills"
  for skill_dir in "${DOTFILES_DIR}"/skills/*/; do
    skill_name=$(basename "${skill_dir}")
    mkdir -p "${CLAUDE_DIR}/skills/${skill_name}"
    for skill_file in "${skill_dir}"*; do
      [[ -f "${skill_file}" ]] || continue
      safe_copy "${skill_file}" "${CLAUDE_DIR}/skills/${skill_name}/$(basename "${skill_file}")"
    done
  done
fi

# ── Copy team baseline memories (non-destructive: new files only) ────────────
if [[ -d "${DOTFILES_DIR}/memory" ]]; then
  for memory in "${DOTFILES_DIR}"/memory/*.md; do
    [[ -f "${memory}" ]] || continue
    safe_copy "${memory}" "${MEMORY_DIR}/$(basename "${memory}")"
  done
fi

# ── Common hooks (always installed) ──────────────────────────────────────────
for hook in audit.sh prompt-guard.sh session-start.sh branch-guard.sh; do
  [[ -f "${DOTFILES_DIR}/hooks/common/${hook}" ]] || continue
  safe_copy "${DOTFILES_DIR}/hooks/common/${hook}" "${HOOKS_DIR}/${hook}"
done

# ── Global hooks (always installed) ──────────────────────────────────────────
mkdir -p "${HOOKS_DIR}/global"
safe_copy "${DOTFILES_DIR}/hooks/global/inject-claude-env.sh" "${HOOKS_DIR}/global/inject-claude-env.sh"

# ── Profile-specific hooks + settings ────────────────────────────────────────
case "${PROFILE}" in
  infra-ops)
    for hook in bash-guard.sh write-guard.sh; do
      [[ -f "${DOTFILES_DIR}/hooks/infra-ops/${hook}" ]] || continue
      safe_copy "${DOTFILES_DIR}/hooks/infra-ops/${hook}" "${HOOKS_DIR}/${hook}"
    done
    safe_copy "${DOTFILES_DIR}/hooks/k8s-devops/yaml-guard.sh" "${HOOKS_DIR}/yaml-guard.sh"
    safe_copy "${DOTFILES_DIR}/hooks/aws-devops/cdk-python-guard.sh" "${HOOKS_DIR}/cdk-python-guard.sh"
    safe_copy "${DOTFILES_DIR}/settings/infra-ops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/infra-ops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/infra-ops.md" "${AGENTS_DIR}/infra-ops.md"
    ;;
  sysops)
    for hook in bash-guard.sh write-guard.sh; do
      [[ -f "${DOTFILES_DIR}/hooks/sysops/${hook}" ]] || continue
      safe_copy "${DOTFILES_DIR}/hooks/sysops/${hook}" "${HOOKS_DIR}/${hook}"
    done
    safe_copy "${DOTFILES_DIR}/settings/sysops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/sysops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/sysops.md" "${AGENTS_DIR}/sysops.md"
    ;;
  k8s-devops)
    for hook in bash-guard.sh yaml-guard.sh; do
      [[ -f "${DOTFILES_DIR}/hooks/k8s-devops/${hook}" ]] || continue
      safe_copy "${DOTFILES_DIR}/hooks/k8s-devops/${hook}" "${HOOKS_DIR}/${hook}"
    done
    safe_copy "${DOTFILES_DIR}/settings/k8s-devops-settings.json" "${CLAUDE_DIR}/settings.json"
    [[ -f "${DOTFILES_DIR}/agents/k8s-devops.md" ]] && safe_copy "${DOTFILES_DIR}/agents/k8s-devops.md" "${AGENTS_DIR}/k8s-devops.md"
    ;;
  aws-devops)
    for hook in bash-guard.sh cdk-python-guard.sh; do
      [[ -f "${DOTFILES_DIR}/hooks/aws-devops/${hook}" ]] || continue
      safe_copy "${DOTFILES_DIR}/hooks/aws-devops/${hook}" "${HOOKS_DIR}/${hook}"
    done
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
  cat > "${CLAUDE_DIR}/.profile" << META
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
