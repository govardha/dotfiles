# CLAUDE.md — Neovim

This file provides guidance to Claude Code when working in the `nvim/` directory.

## Overview

Lua-based Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim). Key design decisions: **offline-first mode** (no network by default), **OS detection** (MSYS2, macOS, Linux, RHEL), **VSCode compatibility** (embedded Neovim skips plugins), and **auto-save on all changes**.

## Directory Structure

```
nvim/
├── init.lua              # Entry point: loads core, filetype detection, offline check
├── lazy-lock.json        # Pinned plugin versions (commit SHAs)
├── .online               # Sentinel: touch to enable online mode
├── lua/gov/
│   ├── core/
│   │   ├── init.lua      # Loads options → keymaps → offline-guard
│   │   ├── options.lua   # Editor settings, OSC 52 clipboard for SSH
│   │   ├── keymaps.lua   # Leader=Space
│   │   └── offline-guard.lua  # is_online() check & user notification
│   ├── lazy.lua          # lazy.nvim bootstrap
│   └── plugins/
│       ├── init.lua      # Always-loaded: plenary, vim-tmux-navigator
│       ├── lsp/
│       │   ├── mason.lua      # LSP/tool installer (OS-aware, offline-guarded)
│       │   └── lspconfig.lua  # LSP server configs + keybinds
│       ├── codecompanion.lua  # AI assistant (Claude Code integration)
│       ├── blink-cmp.lua      # Completion engine
│       ├── treesitter.lua     # Syntax highlighting (d2, jinja2 custom parsers)
│       ├── telescope.lua      # Fuzzy finder
│       ├── formatting.lua     # conform.nvim: format-on-save
│       ├── linting.lua        # nvim-lint: auto-lint on write
│       └── [15+ more plugin files]
└── docs/                 # Notes and migration guides
```

## Key Design Decisions

### Offline-First Mode

By default, the config blocks network-dependent operations (plugin installs, Mason updates). Enable online mode **any one** of:

1. `export NVIM_ONLINE=true`
2. `touch ~/.config/nvim/.online`
3. Hostname contains `online`

When offline, `:Lazy`, `:Mason`, and related commands show a user-friendly error. This is intentional — the config assumes airgapped environments.

### OS Detection

```lua
-- MSYS2 (Windows) detection
vim.g.is_msys2 = vim.fn.has("win32") == 1 and os.getenv("MSYSTEM") ~= nil

-- In plugin specs:
cond = not vim.g.is_msys2  -- Skip heavy plugins on Windows
```

- **MSYS2**: Skips `plugins/lsp/` entirely; skips language-specific plugins
- **RHEL/Ubuntu**: Enables `ansiblels` LSP
- **macOS**: Minimal OS-specific additions
- **Windows line endings**: Force Unix format (`\n`) on Windows

### VSCode Integration

When Neovim runs embedded in VSCode (`vim.g.vscode`), only core options/keymaps load. Lazy.nvim and all plugins are skipped.

### Clipboard Over SSH

Uses custom OSC 52 implementation in `core/options.lua` — copies to local system clipboard over remote SSH sessions without needing X11 forwarding.

### Auto-Save

All buffers auto-save on `TextChanged`, `TextChangedI`, `FocusLost`, and `BufLeave`. Configured in `core/options.lua`.

## Plugin Management

### Adding a New Plugin

1. Create `lua/gov/plugins/<name>.lua` with a lazy.nvim plugin spec:
   ```lua
   return {
     "author/repo",
     dependencies = { "other/plugin" },
     cond = not vim.g.is_msys2,  -- optional: conditional load
     keys = { { "<leader>k", "<cmd>SomeCommand<cr>", desc = "..." } },
     config = function(plugin, opts)
       require("some-setup")
     end,
   }
   ```

2. Lazy auto-discovers it on next nvim startup.

### Updating Plugins

1. Enable online mode: `export NVIM_ONLINE=true`
2. Run `:LazyUpdate` inside Neovim
3. Run `:LazySync` to update `lazy-lock.json`

### First-Time Setup

1. Enable online mode
2. Open nvim — lazy auto-installs plugins
3. Run `:TSInstallAll` to install Treesitter parsers
4. Run `:Mason` to install LSP servers/tools for your languages

### Locking Versions

`lazy-lock.json` tracks exact commit SHAs. To lock/pin a plugin version:
```lua
-- In plugin spec:
commit = "abc123",  -- pins to specific commit
```

Then `:LazySync` to update the lock file.

## LSP Stack

| Component | Plugin | Purpose |
|-----------|--------|---------|
| **Installation** | mason.nvim | Installs LSP servers, formatters, linters (OS-aware) |
| **Configuration** | nvim-lspconfig | Configures language servers and keybinds on attach |
| **Completion** | blink-cmp | Fast completion engine (replaced nvim-cmp) |
| **Formatting** | conform.nvim | Format-on-save with per-language tool selection |
| **Linting** | nvim-lint | Auto-lint on write/enter/leave |
| **Diagnostics** | Trouble | Diagnostics panel with quickfix integration |

### Adding a Language Server

1. Ensure Mason has the server package (search `:Mason` → find language)
2. Add LSP config in `plugins/lsp/lspconfig.lua` under the attachment handler
3. Enable online mode and run `:Mason` to install
4. Open a file of that language — LSP attaches and loads keybinds

## Common Tasks

### Test Configuration Changes

Edit a config file, then reload Neovim:

```vim
:source $MYVIMRC        " Reload init.lua (only reloads what's reload-safe)
:Lazy reload <name>    " Reload a specific plugin module
```

For plugin changes, usually a full `:qa!` and reopen is safest.

### Check if a Plugin Loaded

```vim
:Lazy show <name>      " Show plugin status and loaded state
:Lazy log              " Show load timeline
```

### Debug Offline Mode

When `:Lazy` says "you're offline":

```bash
echo $NVIM_ONLINE              # Check env var
test -f ~/.config/nvim/.online && echo "sentinel exists"
hostname                       # Check if hostname contains "online"
```

## Conventions

1. **Plugin specs**: One file per plugin in `lua/gov/plugins/`.
2. **Keybindings**: Defined in plugin specs under `keys = {...}` or in `core/keymaps.lua`.
3. **OS guards**: Use `cond = not vim.g.is_msys2` or `if vim.fn.has("win32") == 1` for OS-specific code.
4. **Offline guards**: Use `offline_guard.is_online()` before calling `:Lazy` or `:Mason`.

## Testing Strategy

- **Plugin changes**: Edit spec, reload nvim, verify `:Lazy show <name>` shows correct status
- **Keybinding changes**: Open file, test key sequence (e.g., `<leader>t` for telescope)
- **LSP changes**: Open a file with that language, verify diagnostics appear and keybinds work
- **Cross-platform**: Test on both macOS and Linux (MSYS2 can be tested with manual flag)
- **Offline mode**: Disable internet, verify `:Lazy` shows offline error, enable sentinel, re-test

## Related Documentation

- **KIRO.md** — Complete architecture, plugin list, all LSP stack details
- **docs/** — Migration guides and historical notes
- **~/.config/nvim/lazy-lock.json** — Exact plugin versions locked in git
