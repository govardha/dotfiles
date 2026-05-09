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

## What happens when you SSH in

SSH starts bash as a **login shell**. Exact sequence:

```
1. bash reads /etc/profile                          (system-wide, not ours)
2. bash looks for the FIRST file that exists:
     ~/.bash_profile  ← found, stops looking
     ~/.bash_login
     ~/.profile
3. ~/.bash_profile (our bash_profile.loader) runs:
     a. kiro-cli pre hook
     b. source bash_profile.common
          i.   set -o vi
          ii.  source ~/.bashrc  ← this is the key bridge
                 → kiro-cli pre hook
                 → bashrc.common (prompt, aliases, pyenv, nvm, aws, secrets)
                 → hosts/<hostname -s> (machine-specific)
                 → roles/* from ~/.dotfiles-role (class-specific)
                 → kiro-cli post hook
          iii. PATH additions (~/bin, /opt/nvim/bin)
          iv.  aps() + AWS profile completion
          v.   CDK completions
          vi.  bun PATH
          vii. rich PS1 (overwrites the one from bashrc.common)
     c. kiro-cli post hook
4. You get your prompt.
```

**Key detail:** bash only reads `~/.bashrc` automatically for non-login
interactive shells (new terminal tab on Linux). For login shells (SSH), it
does NOT read `~/.bashrc` on its own — that's why `bash_profile.common`
explicitly does `source ~/.bashrc`. Without that line, you'd SSH in and have
no aliases, no prompt, no pyenv.

This is the #1 source of "it works in my terminal but not over SSH" confusion.

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
