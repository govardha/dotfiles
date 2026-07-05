# CLAUDE.md — Bash

This file provides guidance to Claude Code when working in the `bash/` directory.

## Overview

Bash configuration with a **loader-based architecture** for non-destructive installation. Comprises loaders (installed as `~/.bashrc` and `~/.bash_profile`), shared config (`bashrc.common`), a fancy multi-line prompt (`bashrc.ps1`), and role/host-based overrides. Both login and non-login shells load the same configuration.

## Directory Structure

```
bash/
├── install.sh              # Backs up existing dotfiles, installs loaders
├── bashrc.loader           # Installed as ~/.bashrc — entry point
├── bash_profile.loader     # Installed as ~/.bash_profile — login entry point
├── bashrc.common           # Interactive: aliases, tools, PATH, functions
├── bashrc.ps1              # Multi-line prompt with git/pyenv/AWS/kube status
├── bash_profile.common     # Login shell: sources ~/.bashrc, then PATH/completions
├── claude-providers.sh     # Claude/AI provider config (sourced from bashrc.common)
├── hosts/                  # Per-machine overrides (auto-detected by hostname)
│   └── imac-depot          # Example: host-specific config
└── roles/                  # Role-based overrides (from ~/.dotfiles-role)
    ├── depot               # Workstation role (tools, AWS, K8s)
    ├── msys                # Windows MSYS2 role (path adjustments)
    └── vpn                 # VPN role (specific tooling)
```

## Loading Flow

### Non-Login Shell (Linux terminal tab, new window in iTerm, etc.)

```
~/.bashrc (bashrc.loader)
├─ sources bashrc.common
├─ sources bashrc.ps1
├─ sources bash/hosts/<hostname>  (if exists)
└─ sources bash/roles/<role>*     (one per line in ~/.dotfiles-role)
```

### Login Shell (SSH, macOS Terminal, etc.)

```
~/.bash_profile (bash_profile.loader)
├─ sources bash_profile.common
└─ which sources ~/.bashrc
   └─ [same flow as above]
```

Both paths result in the same config: `bashrc.common` + `bashrc.ps1` + host + roles.

## Key Files

| File | Purpose |
|------|---------|
| **bashrc.loader** | Installed as `~/.bashrc` — loads common, ps1, host, roles |
| **bash_profile.loader** | Installed as `~/.bash_profile` — sources bashrc.loader + adds login-shell PATH/completions |
| **bashrc.common** | Shared config: aliases, functions, tool setup (Homebrew, Pyenv, NVM, AWS), EDITOR=nvim, PATH |
| **bashrc.ps1** | Multi-line prompt: shows git status, pyenv version, AWS profile, Kubernetes context |
| **bash_profile.common** | Login shell additions: completions, dynamic completers, `aps()` function |
| **claude-providers.sh** | Claude/AI provider setup (sourced from bashrc.common) |
| **hosts/<hostname>** | Per-machine overrides (e.g., `hosts/imac-depot` for machine-specific vars/functions) |
| **roles/<role>** | Role-based overrides (e.g., `roles/depot` for workstations, `roles/msys` for Windows) |

## Installation & Setup

### First-Time Install

```bash
cd bash
./install.sh
echo "depot" > ~/.dotfiles-role   # Set machine role(s)
```

Then open a new shell.

### `install.sh` Behavior

- **Backs up** existing `~/.bashrc` and `~/.bash_profile` with timestamped `.bak.*` suffix
- **Copies** loaders to `~/.bashrc` and `~/.bash_profile`
- **Logs** actions to syslog with tag `kiro-op`

Subsequent runs are safe — loaders recognize if they're already installed and skip re-backing-up.

## Common Tasks

### Edit Shared Configuration

Edit `bashrc.common` to add:
- **Aliases**: `alias gfgp='git fetch && git pull'`
- **Functions**: `myfunction() { ... }`
- **Tool setup**: Homebrew, Pyenv, NVM paths
- **Environment variables**: `export EDITOR=nvim`

Open a new shell to test.

### Edit the Prompt

Edit `bashrc.ps1`:
- Multi-line PS1 with git status (branch, dirty state)
- Pyenv version
- AWS profile (from `$AWS_PROFILE`)
- Kubernetes context (from `kubectl config current-context`)

Open a new shell to see changes.

### Add a New Machine-Specific Override

1. Run `hostname -s` on the target machine (e.g., `imac-depot`)
2. Create `bash/hosts/<hostname>` with shell code:
   ```bash
   # Machine-specific overrides for imac-depot
   export KUBECONFIG="/path/to/kubeconfig"
   alias myalias='some-command'
   ```

3. Run `./install.sh` on the target
4. Open a new shell to test

### Add a New Role

1. Create `bash/roles/<role-name>` with shell code:
   ```bash
   # Workstation role: depot
   export PATH="/opt/depot/bin:${PATH}"
   alias depot-tool='...'
   ```

2. Add the role to `~/.dotfiles-role`:
   ```bash
   echo "depot" >> ~/.dotfiles-role     # Add single role
   # or:
   echo -e "depot\nvpn" > ~/.dotfiles-role  # Replace with multiple
   ```

3. Open a new shell to test

### Test Configuration Without Installing

```bash
# Source the new config to see what would load:
source bashrc.loader

# Or test a specific role:
export DOTFILES_ROLE="my-new-role"
source bashrc.common
source bashrc.ps1
```

### Debug Which Config Files Loaded

```bash
# Print the loading order:
set -x
source ~/.bashrc
set +x

# Check if a role loaded:
grep "my-role" ~/.dotfiles-role

# Check if a host file exists:
test -f bash/hosts/$(hostname -s) && echo "Host file exists"
```

## Prompt Details

The `bashrc.ps1` prompt shows (on separate lines):

```
[git-branch|dirty] [pyenv-version] [aws-profile] [kube-context]
user@host current-directory $
```

Example:
```
main | pyenv:3.11.0 | profile:staging | minikube
govardha@imac-depot ~/src/aws $
```

**Edit in `bashrc.ps1`**:
- `PS1` variable defines the multi-line format
- Git status: uses `git status -s`
- Pyenv: reads `$PYENV_VERSION` or `pyenv version`
- AWS: reads `$AWS_PROFILE`
- Kube: reads `kubectl config current-context`

## Tool Integration

`bashrc.common` sets up:

| Tool | Setup | Config |
|------|-------|--------|
| **Homebrew** | Path and shell completion | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` |
| **Pyenv** | Version manager for Python | `eval "$(pyenv init - bash)"` |
| **NVM** | Version manager for Node | Sources `~/.nvm/nvm.sh` and completions |
| **AWS** | CLI completion | `complete -C "$(command -v aws_completer)" aws"` |
| **Neovim** | Default editor | `export EDITOR=nvim`, aliases `vi` and `vim` to `nvim` |

All tool sourcing uses `[[ -f ... ]] && source` guards — missing tools are silently skipped.

## Secrets & Private Config

Store in `~/.config/shell/secrets` (never committed):

```bash
# ~/.config/shell/secrets (not in git)
export API_KEY="..."
export GITHUB_TOKEN="..."
```

Sourced from `bashrc.common` with guard: `[[ -f "${HOME}/.config/shell/secrets" ]] && source ...`

## Important Conventions

1. **Sourcing guards**: All files use `[[ -f <path> ]] && source <path>` — missing files are silently OK
2. **Non-destructive installs**: `install.sh` backs up existing files with `.bak.<timestamp>` suffix
3. **Multiple roles**: `~/.dotfiles-role` can have one role per line
4. **Role precedence**: Later roles override earlier ones
5. **Host override precedence**: Host files override roles
6. **KIRO_CLI env**: Exported for git co-author hooks (see global CLAUDE.md)

## Testing Strategy

- **New alias/function**: Open new shell, test it
- **Tool setup**: Verify tool loads without error (e.g., `pyenv --version`)
- **Prompt changes**: Verify all status fields appear correctly
- **Role changes**: Verify environment variables and functions are available
- **Host overrides**: Verify host-specific settings are applied after roles
- **Multi-role**: Test with multiple roles in `~/.dotfiles-role`, verify all load

## Related Documentation

- **CLAUDE.md** (repo root) — Role-based architecture, common tasks
- **KIRO.md** (repo root) — Detailed structure and setup guide
- **README.md** (repo root) — Quick start and feature overview
