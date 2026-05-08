#!/usr/bin/env bash
# Usage: bash /path/to/claude/install.sh [profile]
# Profiles: infra-ops | sysops | k8s-devops | aws-devops | java-dev
# No profile = base only (prompt guard + audit)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
AGENTS_DIR="${CLAUDE_DIR}/agents"
PROFILE="${1:-base}"

mkdir -p "${HOOKS_DIR}" "${AGENTS_DIR}"

# ── Common hooks (always installed) ──────────────────────────────────────────
for hook in audit.sh prompt-guard.sh session-start.sh; do
  cp "${DOTFILES_DIR}/hooks/common/${hook}" "${HOOKS_DIR}/${hook}"
  chmod +x "${HOOKS_DIR}/${hook}"
done

# ── Profile-specific hooks + settings ────────────────────────────────────────
case "${PROFILE}" in
  infra-ops)
    for hook in bash-guard.sh write-guard.sh; do
      cp "${DOTFILES_DIR}/hooks/infra-ops/${hook}" "${HOOKS_DIR}/${hook}"
      chmod +x "${HOOKS_DIR}/${hook}"
    done
    # Reuse k8s yaml-guard and aws cdk-python-guard as-is
    cp "${DOTFILES_DIR}/hooks/k8s-devops/yaml-guard.sh" "${HOOKS_DIR}/yaml-guard.sh"
    chmod +x "${HOOKS_DIR}/yaml-guard.sh"
    cp "${DOTFILES_DIR}/hooks/aws-devops/cdk-python-guard.sh" "${HOOKS_DIR}/cdk-python-guard.sh"
    chmod +x "${HOOKS_DIR}/cdk-python-guard.sh"
    cp "${DOTFILES_DIR}/settings/infra-ops-settings.json" "${CLAUDE_DIR}/settings.json"
    cp "${DOTFILES_DIR}/agents/infra-ops.md" "${AGENTS_DIR}/infra-ops.md"
    ;;
  sysops)
    for hook in bash-guard.sh write-guard.sh; do
      cp "${DOTFILES_DIR}/hooks/sysops/${hook}" "${HOOKS_DIR}/${hook}"
      chmod +x "${HOOKS_DIR}/${hook}"
    done
    cp "${DOTFILES_DIR}/settings/sysops-settings.json" "${CLAUDE_DIR}/settings.json"
    cp "${DOTFILES_DIR}/agents/sysops.md" "${AGENTS_DIR}/sysops.md"
    ;;
  k8s-devops)
    for hook in bash-guard.sh yaml-guard.sh; do
      cp "${DOTFILES_DIR}/hooks/k8s-devops/${hook}" "${HOOKS_DIR}/${hook}"
      chmod +x "${HOOKS_DIR}/${hook}"
    done
    cp "${DOTFILES_DIR}/settings/k8s-devops-settings.json" "${CLAUDE_DIR}/settings.json"
    cp "${DOTFILES_DIR}/agents/k8s-devops.md" "${AGENTS_DIR}/k8s-devops.md"
    ;;
  aws-devops)
    for hook in bash-guard.sh cdk-python-guard.sh; do
      cp "${DOTFILES_DIR}/hooks/aws-devops/${hook}" "${HOOKS_DIR}/${hook}"
      chmod +x "${HOOKS_DIR}/${hook}"
    done
    cp "${DOTFILES_DIR}/settings/aws-devops-settings.json" "${CLAUDE_DIR}/settings.json"
    cp "${DOTFILES_DIR}/agents/aws-devops.md" "${AGENTS_DIR}/aws-devops.md"
    ;;
  java-dev)
    cp "${DOTFILES_DIR}/settings/base-settings.json" "${CLAUDE_DIR}/settings.json"
    cp "${DOTFILES_DIR}/agents/java-dev.md" "${AGENTS_DIR}/java-dev.md"
    ;;
  base)
    cp "${DOTFILES_DIR}/settings/base-settings.json" "${CLAUDE_DIR}/settings.json"
    ;;
  *)
    echo "Unknown profile: ${PROFILE}" >&2
    echo "Valid: infra-ops | sysops | k8s-devops | aws-devops | java-dev | base" >&2
    exit 1
    ;;
esac

echo "Installed profile '${PROFILE}' → ${CLAUDE_DIR}"
echo "Hooks:"
ls -1 "${HOOKS_DIR}"
echo "Agents:"
ls -1 "${AGENTS_DIR}"
