# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles is a personal shell and editor configuration system designed for role-based machine layering. It manages bash, vim/nvim, VSCode, WezTerm, tmux, lazygit, and SSH configurations across multiple machines with different roles (depot for workstations, msys for Windows, vpn for VPN machines, etc.).

## Architecture & Loading System

### Bash Configuration Loading

The system uses a **loader-based architecture** for non-destructive installation:

```
User opens shell
  ↓
~/.bashrc (bashrc.loader)
  ↓
├─ bashrc.common (shared aliases, functions, PATH)
├─ bashrc.ps1 (prompt with git/pyenv/AWS/kube status)
├─ bash/hosts/<hostname> (per-machine overrides)
└─ bash/roles/<role-name> (role-based overrides)
```

Both login shells (`.bash_profile`) and non-login shells (`.bashrc`) load the same configuration through sourcing. The `install.sh` script backs up any existing `~/.bashrc` with a timestamped `.bak.*` suffix.

### Role-Based Layering

Roles are machine-class configurations. For example:
- `depot` — development workstations (adds tools, AWS config, K8s context)
- `msys` — Windows MSYS2 environment (path adjustments, Windows-specific tools)
- `vpn` — VPN machines (specific tooling and overrides)

A machine can have multiple roles (one per line in `~/.dotfiles-role`).

### Host-Specific Overrides

Individual machines get per-machine overrides in `bash/hosts/<hostname>` (where hostname comes from `hostname -s`). These load after roles and take precedence.

## Common Tasks

### Install or Update Bash Configuration

```bash
cd bash
./install.sh
```

This backs up existing dotfiles and installs loaders. Then set or update the machine's role:

```bash
echo "depot" > ~/.dotfiles-role  # single role
# or multiple roles:
echo -e "depot\nvpn" > ~/.dotfiles-role
```

Open a new shell to apply changes.

### Test Configuration Changes

After editing bash config files (`bashrc.common`, `bashrc.ps1`, roles, hosts), open a new shell to see changes. No install step needed for existing installations.

```bash
# To test without opening a new shell:
source ~/.bashrc
```

### Add a New Host

1. Run `hostname -s` on the target machine
2. Create `bash/hosts/<hostname>` with machine-specific overrides (see `bash/hosts/imac-depot` for an example)
3. Run `./install.sh` on the target

### Add a New Role

1. Create `bash/roles/<role-name>` with shell code
2. Add the role to `~/.dotfiles-role`: `echo "role-name" >> ~/.dotfiles-role`
3. Open a new shell to test

### Edit Other Tool Configurations

- **Neovim**: `nvim/init.lua` and `nvim/lua/` (uses lazy.nvim plugin manager)
- **WezTerm**: `wezterm/` YAML configs
- **Lazygit**: `lazygit/config.yml` (uses delta for side-by-side diffs; requires `delta` binary)
- **VSCode**: `vscode/settings.json` and keybindings
- **Tmux**: `tmux/tmux.conf`
- **SSH**: `ssh/config` and SSH-related setup

Each tool has its own `install.sh` (except neovim, which uses lazy.nvim directly).

## Key Files & Directories

| File/Dir | Purpose |
|----------|---------|
| `bash/bashrc.loader` | Installed as `~/.bashrc` — entry point |
| `bash/bash_profile.loader` | Installed as `~/.bash_profile` — login shell entry point |
| `bash/bashrc.common` | Aliases, functions, PATH, tools config (shared) |
| `bash/bashrc.ps1` | Multi-line prompt with git/pyenv/AWS/kube status |
| `bash/claude-providers.sh` | Claude/AI provider configuration |
| `bash/roles/` | Role-based configs (depot, msys, vpn, etc.) |
| `bash/hosts/` | Per-machine overrides |
| `nvim/` | Neovim config (lazy.nvim, Lua plugins) |
| `wezterm/` | WezTerm terminal config |
| `lazygit/` | Lazygit TUI git client config |
| `vscode/` | VSCode settings and keybindings |
| `tmux/` | Tmux terminal multiplexer config |
| `ssh/` | SSH config and setup |
| `KIRO.md` | Detailed architecture and setup guide |
| `README.md` | Quick start and feature overview |

## Important Conventions

1. **Sourcing guards**: All sourced files use `[[ -f ... ]] && source` — missing files are silently skipped
2. **Non-destructive installs**: `install.sh` scripts back up existing files with timestamped `.bak.*` suffix before overwriting
3. **Secrets**: Store sensitive config in `~/.config/shell/secrets` (never committed to repo)
4. **Environment variables**: The `KIRO_CLI=1` env var is exported for git co-author hooks (see global CLAUDE.md)
5. **Multi-shell support**: All bash configs work in bash, zsh, and other POSIX shells where applicable

## Dependencies

- **Git** — for version control
- **Delta** — for side-by-side diffs in lazygit (`brew install git-delta` or see KIRO.md for Linux install)
- **Nerd Font v3** — for icons in shells and editors (optional but recommended)

## Testing Strategy

Since this is a configuration repo with no tests, validate changes by:
1. Opening a new shell and checking behavior (aliases, functions, prompt)
2. Testing role-specific behavior by verifying environment variables and tools
3. For editor configs, verify keybindings and plugin loading in the respective editor
4. For lazygit, verify delta integration and config options work as expected

## Related Documentation

- **KIRO.md** — Complete setup guide, structure, and architecture details
- **README.md** — Quick start and feature overview
- **Global CLAUDE.md** — Coding style, git workflow, and co-author footer rules
