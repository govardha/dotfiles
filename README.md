# Dotfiles

Personal shell and editor configuration designed to work on any Linux/macOS/MSYS2 host via a role-based layering system.

## Quick Start

```bash
cd ~/src/dotfiles/bash
./install.sh
echo "depot" > ~/.dotfiles-role   # assign role(s)
```

Then open a new shell.

## Features

- **Role-based layering**: Configure different setups for different machine types
- **Host-specific overrides**: Per-machine customization automatically detected
- **Multi-shell support**: Works on bash, zsh, and other shells
- **Editor configs**: Neovim, VSCode, and WezTerm configurations
- **Shell tools**: Lazygit, tmux, and SSH configurations

## Documentation

- [KIRO.md](./KIRO.md) — Complete setup guide, structure, and architecture
- [bash/](./bash/) — Shell configuration and installers
- [nvim/](./nvim/) — Neovim configuration
- [lazygit/](./lazygit/) — Lazygit configuration
- [wezterm/](./wezterm/) — WezTerm configuration
- [tmux/](./tmux/) — Tmux configuration
- [vscode/](./vscode/) — VSCode configuration
- [ssh/](./ssh/) — SSH configuration

## Architecture

Roles are class-of-machine configs (e.g., `depot` for workstations, `msys` for Windows).

```
~/.bashrc
├── bashrc.loader
├── bashrc.common         (shared config)
├── bashrc.ps1           (prompt)
├── hosts/<hostname>     (per-machine overrides)
└── roles/<role>         (role-based overrides)
```

Both login and non-login shells load the same config. See [KIRO.md](./KIRO.md) for detailed structure.

## Requirements

- Git
- Delta (for side-by-side diffs in lazygit)
- Nerd Font v3 (for icons)

## License

Personal configuration. Feel free to reference for ideas.
