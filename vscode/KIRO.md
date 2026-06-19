# VSCode Dotfiles

Portable VS Code configuration for a **Windows/macOS client → Linux remote** workflow (RHEL 8 or Ubuntu 24/26 via Remote-SSH).

## File Layout

| File | Scope | Location on disk |
|------|-------|------------------|
| `settings-client.json` | Local machine (Win/macOS) | See platform sections below |
| `settings-server.json` | Remote Linux host | `~/.vscode-server/data/Machine/settings.json` |
| `keybindings.json` | Local machine (Win/macOS) | Same parent as client settings |

## Setup on a New Windows Machine

VS Code is installed as a portable/extracted zip at `C:\DevSoftware\VSCode-win32-x64-<version>` with a self-contained `data` directory. Settings live inside the install folder itself.

```bash
# From Git Bash / MSYS2
git clone git@github.com:govardha/dotfiles.git ~/src/dotfiles

# Copy settings into the VS Code data directory
VSCODE_DIR="/c/DevSoftware/VSCode-win32-x64-1.124.2"
cp ~/src/dotfiles/vscode/settings-client.json "${VSCODE_DIR}/data/user-data/User/settings.json"
cp ~/src/dotfiles/vscode/keybindings.json "${VSCODE_DIR}/data/user-data/User/keybindings.json"
```

> When upgrading VS Code versions, copy the entire `data/` directory to the new install folder — all settings, extensions, and state carry over.

## Setup on a New macOS Machine

```bash
# Clone the repo
git clone git@github.com:govardha/dotfiles.git ~/src/dotfiles

# Symlink client settings & keybindings
code_dir="$HOME/Library/Application Support/Code/User"
ln -sf ~/src/dotfiles/vscode/settings-client.json "${code_dir}/settings.json"
ln -sf ~/src/dotfiles/vscode/keybindings.json "${code_dir}/keybindings.json"
```

## Setup on the Remote Linux Host (RHEL 8 / Ubuntu 24/26)

The server settings are applied automatically once the remote connects, but to manage them via this repo:

```bash
mkdir -p ~/.vscode-server/data/Machine
ln -sf ~/src/dotfiles/vscode/settings-server.json ~/.vscode-server/data/Machine/settings.json
```

## Prerequisites

### Client (Windows/macOS)

- VS Code with **Remote - SSH** extension
- Neovim (Windows path configured in `settings-client.json`)
- Font: [JetBrains Mono](https://www.jetbrains.com/lp/mono/)

### Remote (Linux)

- Python 3 at `/apps/ops/python3/bin/python3` (or update `python.defaultInterpreterPath`)
- `shfmt` at `/apps/ops/bin/shfmt`
- `shellcheck` installed
- `ruff` installed (`pip install ruff`)
- JSON schemas pre-downloaded to `~/.schemas/` (offline/air-gapped environments)

## Design Decisions

- **Air-gapped friendly** — schema downloads disabled; all schemas are local files under `~/.schemas/`.
- **Telemetry off** — updates, experiments, and AI features disabled on both client and server.
- **Neovim-first editing** — keybindings allow system clipboard copy/paste while in neovim visual/insert modes.
- **Helm before YAML** — file associations order ensures Helm templates get proper language support.
