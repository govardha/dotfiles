#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${0}")" && pwd)"

backup_and_install() {
  local name="${1}"
  local target="${HOME}/.${name}"
  local loader="${DOTFILES_DIR}/${name}.loader"

  if [[ -f "${target}" ]] && ! grep -q "dotfiles loader" "${target}" 2>/dev/null; then
    cp "${target}" "${target}.bak.$(date +%s)"
    logger -t kiro-op "backed up ${target}"
  fi

  cp "${loader}" "${target}"
  logger -t kiro-op "installed ${target} from dotfiles"
}

backup_and_install bashrc
backup_and_install bash_profile

# Shell config dir
mkdir -p "${HOME}/.config/shell"
cp "${DOTFILES_DIR}/claude-providers.sh" "${HOME}/.config/shell/claude-providers.sh"
logger -t kiro-op "installed claude-providers.sh"

echo "Installed .bashrc and .bash_profile loaders."
echo "Set role: echo 'depot' > ~/.dotfiles-role"
