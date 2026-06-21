# Neovim Configuration — KIRO.md

Reference document for this Neovim config repo. Use this to understand structure, conventions, and how to make changes.

## Overview

Personal Neovim configuration for `govardha`. Lua-based, managed by [lazy.nvim](https://github.com/folke/lazy.nvim), with an offline/airgapped-first design. Supports macOS, Ubuntu, RHEL, and MSYS2 (Windows) with OS-detection logic throughout.

## Directory Structure

```
nvim/
├── init.lua                          # Entry point: loads core, filetype detection, vscode guard
├── lazy-lock.json                    # Pinned plugin versions (gitignored in tracking)
├── .online                           # Sentinel file: presence enables online mode
├── .gitignore
├── docs/                             # Notes and migration guides
├── lua/gov/
│   ├── core/
│   │   ├── init.lua                  # Loads options → keymaps → offline-guard
│   │   ├── options.lua               # Editor settings, clipboard (OSC 52 for SSH), auto-save
│   │   ├── keymaps.lua               # Leader=Space, general keymaps
│   │   └── offline-guard.lua         # Utility: is_online() check & user notification
│   ├── lazy.lua                      # lazy.nvim bootstrap + offline-aware config
│   └── plugins/
│       ├── init.lua                  # Always-loaded: plenary, vim-tmux-navigator
│       ├── lsp/
│       │   ├── mason.lua             # Mason: LSP/tool installer (OS-aware, offline-guarded)
│       │   └── lspconfig.lua         # LSP server configs + keybinds on LspAttach
│      ├── codecompanion.lua         # AI assistant (Groq, OpenRouter, Claude Code)
│       ├── blink-cmp.lua            # Completion engine (replaced nvim-cmp)
│       ├── treesitter.lua            # Syntax highlighting + custom parsers (d2, jinja2)
│       ├── telescope.lua             # Fuzzy finder + Trouble integration
│       ├── formatting.lua            # conform.nvim: format-on-save
│       ├── linting.lua               # nvim-lint: auto-lint on write/enter/leave
│       ├── colorscheme.lua           # tokyonight (night, custom palette)
│       ├── lualine.lua               # Statusline
│       ├── nvim-tree.lua             # File explorer
│       ├── oil.lua                   # Buffer-based file manager
│       ├── alpha.lua                 # Dashboard
│       ├── auto-session.lua          # Session persistence
│       ├── bufferline.lua            # Tab-like buffer bar
│       ├── which-key.lua             # Keymap hint popup
│       ├── trouble.lua               # Diagnostics panel
│       ├── todo-comments.lua         # Highlight TODO/FIXME/etc.
│       ├── nvim-treesitter-text-objects.lua
│       ├── autopairs.lua
│       ├── comment.lua
│       ├── d2.lua                    # D2 diagram filetype support
│       ├── dressing.lua              # Improved UI (select/input)
│       ├── indent-blankline.lua
│       ├── lazygit.lua
│       └── vim-maximizer.lua
```

## Key Design Decisions

### Offline-First / Airgapped Mode

By default, the config assumes **no internet**. Plugin installs, updates, and Mason operations are blocked unless online mode is enabled.

Enable online mode (any one):
1. `export NVIM_ONLINE=true`
2. `touch ~/.config/nvim/.online`
3. Hostname contains `online`

When offline, Lazy and Mason commands that require network are guarded with user-friendly error messages.

### OS Detection

Multiple plugins use `vim.loop.os_uname()` to conditionally load features:
- **MSYS2**: LSP directory (`plugins/lsp/`) is skipped entirely; `cond = not vim.g.is_msys2` gates heavy plugins.
- **RHEL/Ubuntu**: Gets `ansiblels` LSP.
- **macOS**: Minimal OS-specific additions.

### VSCode Integration

When running as a VSCode embedded Neovim (`vim.g.vscode`), only core options/keymaps load — lazy.nvim and plugins are skipped.

### Clipboard

- **SSH sessions**: Custom OSC 52 implementation for copy-to-system-clipboard over remote connections.
- **Local**: Uses `unnamedplus` (system clipboard).

### Auto-Save

All buffers auto-save on `TextChanged`, `TextChangedI`, `FocusLost`, and `BufLeave`.

## Plugin Management

- **Package manager**: lazy.nvim (stable branch)
- **Lock file**: `lazy-lock.json` — tracks exact commit SHAs
- **Install new plugins**: Add a file in `lua/gov/plugins/` returning a lazy.nvim plugin spec
- **Update**: `:LazyUpdate` (requires online mode)
- **First-time setup**: Enable online mode, open nvim, lazy auto-installs. Then run `:TSInstallAll` for treesitter parsers.

## LSP Stack

| Component | Plugin |
|-----------|--------|
| Server management | mason.nvim + mason-lspconfig |
| Configuration | nvim-lspconfig (native `vim.lsp.config()`) |
| Completion | blink.cmp |
| Formatting | conform.nvim (format-on-save) |
| Linting | nvim-lint (lint on write/enter) |

### Configured LSP Servers

Common: `pyrefly`, `bashls`, `perlnavigator`, `jsonls`, `yamlls`, `emmylua_ls`, `docker_compose_language_service`
Linux-only: `ansiblels`

### Formatters

| Filetype | Formatter | Config |
|----------|-----------|--------|
| Python | ruff (organize imports + format) | — |
| sh/bash | shfmt | `-i 2 -ci` |
| yaml/json/xml/markdown | prettier | — |
| Lua | stylua | — |

### Linters

| Filetype | Linter |
|----------|--------|
| Python | ruff |
| sh/bash | shellcheck |
| yaml | yamllint |
| json | jsonlint |
| dockerfile | hadolint |

## Keybindings

Leader key: `Space`

### General

| Key | Mode | Action |
|-----|------|--------|
| `jk` | Insert | Exit insert mode |
| `<leader>nh` | Normal | Clear search highlights |
| `<leader>+` / `<leader>-` | Normal | Increment / decrement number |
| `<leader>sv` | Normal | Split vertically |
| `<leader>sh` | Normal | Split horizontally |
| `<leader>se` | Normal | Equalize splits |
| `<leader>sx` | Normal | Close split |
| `<leader>to/tx/tn/tp/tf` | Normal | Tab operations |

### LSP (buffer-local on attach)

| Key | Action |
|-----|--------|
| `gR` | Telescope references |
| `gD` | Go to declaration |
| `gd` | Telescope definitions |
| `gi` | Telescope implementations |
| `gt` | Telescope type definitions |
| `K` | Hover docs |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename |
| `<leader>D` | Buffer diagnostics |
| `<leader>d` | Line diagnostics |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>rs` | Restart LSP |

### Telescope

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fr` | Recent files |
| `<leader>fs` | Live grep |
| `<leader>fc` | Grep word under cursor |
| `<leader>ft` | Find TODOs |
| `<leader>fk` | Keymaps |

### AI (CodeCompanion)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ak` | n/v | Chat with Kiro adapter |
| `<leader>ac` | n/v | Chat with Claude Code |
| `<leader>ag` | n/v | Chat with Groq |
| `<leader>ao` | n/v | Chat with OpenRouter |
| `<leader>ai` | n/v | Inline edit (Groq) |
| `<leader>aI` | n/v | Inline edit (OpenRouter) |
| `<leader>at` | n/v | Toggle chat buffer |
| `<C-a>` | n/v | Action palette |
| `ga` | Visual | Add selection to chat |
| `<leader>ae` | Visual | Explain code |
| `<leader>af` | Visual | Fix code |
| `<leader>aT` | Visual | Generate tests |
| `<leader>am` | Normal | Generate commit message |

### Other

| Key | Action |
|-----|--------|
| `<leader>mp` | Format file/range |
| `<leader>l` | Trigger lint |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `NVIM_ONLINE` | Set to `true` to enable plugin install/update |
| `GROQ_API_KEY` | Groq LLM access for CodeCompanion |
| `OPENROUTER_API_KEY` | OpenRouter LLM access for CodeCompanion |

## Conventions for Changes

- **Lua style**: 2-space indent, StyLua formatting, no trailing whitespace.
- **One plugin per file** in `lua/gov/plugins/`. Filename matches the plugin's primary purpose.
- **LSP plugins** go in `lua/gov/plugins/lsp/` subdirectory.
- **Conditional loading**: Use `cond = not vim.g.is_msys2` for plugins that can't run on MSYS2.
- **Offline guard**: Any new command that requires network must be wrapped with `offline_guard.check_online()`.
- **OS-specific logic**: Use `vim.loop.os_uname()` detection pattern from `mason.lua` — don't hardcode paths.
- **No `:latest`**: Pin plugin versions via lazy-lock.json; use `version = "X.*"` or `branch = "stable"` in specs.
- **Keymaps**: General keymaps in `core/keymaps.lua`; plugin-specific keymaps inside the plugin's `config` function.
- **Filetype additions**: Add custom filetypes in `init.lua`'s `vim.filetype.add()` block.

## New Machine Setup

1. Clone this repo to `~/.config/nvim` (or symlink)
2. Enable online mode: `touch ~/.config/nvim/.online`
3. Open `nvim` — lazy.nvim bootstraps and installs all plugins
4. Run `:MasonInstall` if any tools are missing
5. Run `:TSInstallAll` for treesitter parsers
6. Remove `.online` if the machine should be airgapped going forward
