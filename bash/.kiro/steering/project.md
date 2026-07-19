# Bash Dotfiles

This directory contains bash configuration with a **loader-based architecture** for non-destructive installation. Comprises loaders (installed as `~/.bashrc` and `~/.bash_profile`), shared config (`bashrc.common`), a fancy multi-line prompt (`bashrc.ps1`), and role/host-based overrides.

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

### Non-Login Shell

```
~/.bashrc (bashrc.loader)
├─ sources bashrc.common
├─ sources bashrc.ps1
├─ sources bash/hosts/<hostname>  (if exists)
└─ sources bash/roles/<role>*     (one per line in ~/.dotfiles-role)
```

### Login Shell

```
~/.bash_profile (bash_profile.loader)
├─ sources bash_profile.common
└─ which sources ~/.bashrc → [same flow as above]
```

## Key Conventions

1. **Sourcing guards**: All files use `[[ -f <path> ]] && source <path>` — missing files are silently OK
2. **Non-destructive installs**: `install.sh` backs up existing files with `.bak.<timestamp>` suffix
3. **Multiple roles**: `~/.dotfiles-role` can have one role per line
4. **Role precedence**: Later roles override earlier ones
5. **Host override precedence**: Host files override roles
6. **Tool guards**: All tool sourcing (Homebrew, Pyenv, NVM) uses existence checks — missing tools are silently skipped

## Common Tasks

### Testing changes

```bash
# Source config in current shell to test:
source bashrc.loader

# Or open a new shell
```

### Adding aliases/functions

Edit `bashrc.common`. Open a new shell to test.

### Editing the prompt

Edit `bashrc.ps1`. The prompt is multi-line showing git status, pyenv version, AWS profile, and kube context.

### Adding a new host override

1. `hostname -s` on the target machine
2. Create `hosts/<hostname>` with shell code
3. Run `./install.sh`

### Adding a new role

1. Create `roles/<role-name>` with shell code
2. Add role name to `~/.dotfiles-role` (one per line)

## Secrets

Store in `~/.config/shell/secrets` (never committed). Sourced from `bashrc.common` with a guard.

## Tool Integration

`bashrc.common` sets up: Homebrew, Pyenv, NVM, AWS CLI completion, and Neovim as default editor. All with existence guards.
