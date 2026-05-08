#!/usr/bin/env bash
# Install kiro dotfiles — single broad profile
# Usage: bash kiro/install.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_DIR="${HOME}/.kiro"
HOOKS_DIR="${KIRO_DIR}/hooks"
AGENTS_DIR="${KIRO_DIR}/agents"
STEERING_DIR="${KIRO_DIR}/steering"

mkdir -p "${HOOKS_DIR}" "${AGENTS_DIR}" "${STEERING_DIR}"

# ── Set up global git hooks ──────────────────────────────────────────────────
GIT_HOOKS_DIR="${HOME}/.git-hooks"
mkdir -p "${GIT_HOOKS_DIR}"
src="${DOTFILES_DIR}/hooks/global/prepare-commit-msg"
dest="${GIT_HOOKS_DIR}/prepare-commit-msg"
if [[ "$(realpath "${src}")" != "$(realpath "${dest}" 2>/dev/null)" ]]; then
  cp "${src}" "${dest}"
  chmod +x "${dest}"
fi
git config --global core.hooksPath "${GIT_HOOKS_DIR}"

# ── Install hooks ────────────────────────────────────────────────────────────
for hook in "${DOTFILES_DIR}"/hooks/*.sh; do
  dest="${HOOKS_DIR}/$(basename "${hook}")"
  [[ "$(realpath "${hook}")" == "$(realpath "${dest}" 2>/dev/null)" ]] && continue
  cp "${hook}" "${dest}"
  chmod +x "${dest}"
done

# ── Install agent config ─────────────────────────────────────────────────────
src="${DOTFILES_DIR}/agents/default.json"
dest="${AGENTS_DIR}/default.json"
if [[ "$(realpath "${src}")" != "$(realpath "${dest}" 2>/dev/null)" ]]; then
  cp "${src}" "${dest}"
fi

# ── Install steering files ───────────────────────────────────────────────────
for file in "${DOTFILES_DIR}"/steering/*.md; do
  dest="${STEERING_DIR}/$(basename "${file}")"
  [[ "$(realpath "${file}")" == "$(realpath "${dest}" 2>/dev/null)" ]] && continue
  cp "${file}" "${dest}"
done

echo "Installed kiro config → ${KIRO_DIR}"
echo "Hooks:"
ls -1 "${HOOKS_DIR}"
echo "Steering:"
ls -1 "${STEERING_DIR}"
