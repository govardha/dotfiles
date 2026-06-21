# Dotfiles

Personal shell and editor configuration, designed to work on any Linux/macOS/MSYS2 host via a role-based layering system.

## Structure

```
bash/
├── install.sh              # Backs up existing dotfiles, installs loaders
├── bashrc.loader           # Installed as ~/.bashrc
├── bash_profile.loader     # Installed as ~/.bash_profile
├── bashrc.common           # Interactive: aliases, tools, PATH, functions
├── bashrc.ps1              # Fancy multi-line PS1 (git, pyenv, AWS, kube)
├── bash_profile.common     # Login shell: sources ~/.bashrc, then adds PATH, completions, aps()
├── claude-providers.sh     # Claude/AI provider config
├── hosts/<hostname -s>     # Per-machine overrides (auto-detected)
└── roles/<role-name>       # Class-of-machine overrides (from ~/.dotfiles-role)
```

## Install

```bash
cd ~/src/dotfiles/bash
./install.sh
echo "depot" > ~/.dotfiles-role   # assign role(s), one per line
```

Then open a new shell.

## How It Works

Both login and non-login shells get the same PS1 and config:

- **Login shell** (SSH, macOS terminal): `~/.bash_profile` → `bash_profile.common` → sources `~/.bashrc` → `bashrc.common` + `bashrc.ps1` + host + roles
- **Non-login shell** (Linux terminal tab): `~/.bashrc` → `bashrc.common` + `bashrc.ps1` + host + roles

The PS1 is defined once in `bashrc.ps1` and used in both paths.

## Adding a Machine

1. Run `hostname -s` on the target
2. Create `bash/hosts/<that-name>` with machine-specific overrides
3. Run `./install.sh`

## Roles

Roles are class-of-machine configs (e.g., `depot` for workstations, `msys` for Windows/MSYS2).

- Set on machine: `echo "role-name" >> ~/.dotfiles-role`
- Multiple roles supported (one per line)
- System-wide alternative: `/etc/dotfiles-role`

## Lazygit

Config lives in `lazygit/config.yml`, deployed to `~/.config/lazygit/config.yml`.

Settings:
- Uses `delta --side-by-side` as pager for side-by-side diffs
- Nerd Fonts v3 icons enabled

Requires: `delta` — install via one of:
- Homebrew: `brew install git-delta`
- Standalone binary (linux x86_64):
  ```bash
  curl -Lo /tmp/delta.tar.gz \
    https://github.com/dandavison/delta/releases/latest/download/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz
  tar -xzf /tmp/delta.tar.gz -C /tmp && sudo cp /tmp/delta-*/delta /usr/local/bin/
  ```

## Conventions

- All sourced files use `[[ -f ... ]] && source` guards — missing files are silently skipped
- Destructive installs back up originals with timestamped `.bak.*` suffix
- Secrets live in `~/.config/shell/secrets` (never committed)
- `KIRO_CLI=1` is exported for git co-author hooks
