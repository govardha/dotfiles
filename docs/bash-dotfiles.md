# Bash Dotfiles

## How bash invocation works

```
┌─────────────────────────────────────────────────────────────────┐
│ Login shell (ssh, first terminal on macOS, `bash --login`)      │
│   → reads: /etc/profile                                         │
│   → reads FIRST found: ~/.bash_profile | ~/.bash_login | ~/.profile │
│                                                                 │
│ Interactive non-login shell (new tab in most Linux terminals)   │
│   → reads: ~/.bashrc                                            │
│                                                                 │
│ macOS Terminal.app / iTerm2: every new tab = login shell        │
│ Linux gnome-terminal / wezterm: every new tab = non-login shell │
└─────────────────────────────────────────────────────────────────┘
```

Because of this split, our `bash_profile.common` sources `~/.bashrc` early so
login shells also get interactive config. This is the standard pattern.

## Load order after install

```
~/.bash_profile (bash_profile.loader)
  ├── kiro-cli pre hook
  ├── bash_profile.common
  │     ├── set -o vi
  │     ├── source ~/.bashrc  ──────────────────────┐
  │     │                                           │
  │     │   ~/.bashrc (bashrc.loader)               │
  │     │     ├── kiro-cli pre hook                 │
  │     │     ├── bashrc.common                     │
  │     │     │     ├── prompt (PS1)                │
  │     │     │     ├── homebrew                    │
  │     │     │     ├── aliases (vi, gfgp, etc.)    │
  │     │     │     ├── pyenv                       │
  │     │     │     ├── nvm                         │
  │     │     │     ├── aws completer               │
  │     │     │     └── secrets (from ~/.config/)   │
  │     │     ├── hosts/<hostname -s>               │
  │     │     ├── roles/* (from ~/.dotfiles-role)   │
  │     │     └── kiro-cli post hook                │
  │     │                                           │
  │     ├── PATH additions (/opt/nvim, ~/bin)  ◄────┘
  │     ├── aps() + AWS profile completion
  │     ├── CDK completions
  │     ├── bun
  │     └── rich PS1 (overrides bashrc PS1 for login shells)
  └── kiro-cli post hook
```

For a **non-login shell** (new Linux terminal tab), only `~/.bashrc` runs —
you get the bashrc.common + host + role layers.

## File layout

```
~/src/dotfiles/bash/
├── bashrc.common          # interactive shell: prompt, aliases, tools
├── bash_profile.common    # login shell: PATH, completions, aps()
├── bashrc.loader          # installed as ~/.bashrc
├── bash_profile.loader    # installed as ~/.bash_profile
├── install.sh             # backs up originals, drops loaders
├── hosts/
│   └── <hostname -s>      # per-machine overrides (auto-detected)
└── roles/
    └── <role-name>         # class-of-machine overrides
```

## Install on a new machine

```bash
cd ~/src/dotfiles/bash
./install.sh
```

This will:
1. Back up existing `~/.bashrc` and `~/.bash_profile` (timestamped `.bak.*`)
2. Install the loader files in their place

Then assign a role:

```bash
echo "depot" > ~/.dotfiles-role
```

Multiple roles (one per line) are supported.

## Test without installing (dry run)

Source the loader in a subshell to verify nothing breaks:

```bash
bash --norc --noprofile -c 'source ~/src/dotfiles/bash/bashrc.loader && echo "OK: $PS1"'
```

Or start a full interactive test shell:

```bash
env -i HOME="$HOME" TERM="$TERM" bash --rcfile ~/src/dotfiles/bash/bashrc.loader
```

This gives you a fresh shell using the new config without touching your
current `~/.bashrc`. Exit to return to your original session.

To test the login-shell path:

```bash
env -i HOME="$HOME" TERM="$TERM" bash --login --rcfile ~/src/dotfiles/bash/bash_profile.loader
```

## Adding a new machine

1. `hostname -s` on the machine to get its short name
2. Create `bash/hosts/<that-name>` with overrides
3. Optionally set `~/.dotfiles-role` for shared role config

## Adding a new role

1. Create `bash/roles/<role-name>`
2. On target machines: `echo "<role-name>" >> ~/.dotfiles-role`
