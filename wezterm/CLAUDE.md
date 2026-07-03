# CLAUDE.md — WezTerm

This file provides guidance to Claude Code when working in the `wezterm/` directory.

## Overview

Modular WezTerm configuration with **auto-discovered SSH nodes** from `~/.ssh/config`, **tmux-style keybindings** (Ctrl+B leader), and **platform-specific environment detection**. Supports macOS, Windows (work/home), and Linux (Ubuntu 24/26) with separate node groups and launch menus per platform.

## Directory Structure

```
wezterm/
├── wezterm.lua                 # Entry point: loads modules and plugins via safe_require()
├── modules/
│   ├── appearance.lua          # Colors (Everforest Dark Hard), fonts, window chrome
│   ├── format.lua              # Tab title format and status bar (clock)
│   ├── keybindings.lua         # Leader key (Ctrl+B), Ctrl+B plugin loader
│   ├── misc.lua                # Paste newline handling (tmux compatibility)
│   ├── mouse.lua               # Triple-click select, right-click copy/paste
│   ├── nodes_config.lua        # SSH config parser, node grouping, launch menu
│   ├── platform_specific.lua   # OS detection, per-platform shell and fonts
│   ├── ssh_utils.lua           # Remote WezTerm path config for mux domains
│   └── startup.lua             # Auto-workspace creation on launch
├── plugins/
│   └── wez-tmux/               # Tmux-style plugin (Ctrl+B leader, pane/workspace management)
│       └── plugin/init.lua
├── docs/
│   └── ssh-config-guide.md     # SSH config structure with Include directives
├── DockerFile                  # Build WezTerm from source (CentOS Stream 8)
└── BUILD-README.md             # Docker build instructions
```

## Module Reference

| Module | Purpose | Key Config |
|--------|---------|-----------|
| **appearance.lua** | Color scheme, fonts, window look | Everforest Dark Hard, JetBrains Mono 12pt, padding, 10k scrollback |
| **format.lua** | Tab bar styling | Active: purple bg + icon. Inactive: black bg. Right status: clock |
| **keybindings.lua** | Keybinds and leader setup | Leader = `Ctrl+B`, loads wez-tmux plugin, `Alt+L` launcher |
| **misc.lua** | Paste/terminal behavior | `canonicalize_pasted_newlines = "CarriageReturn"` for tmux compat |
| **mouse.lua** | Mouse interactions | Triple-click semantic select, right-click copy/paste |
| **nodes_config.lua** | SSH node discovery and grouping | Reads `~/.ssh/config`, groups by pattern/explicit list, builds launch menu |
| **platform_specific.lua** | OS detection and platform config | Detects via `target_triple`, sets shell/fonts/paths per platform |
| **ssh_utils.lua** | Remote WezTerm setup | Sets `remote_wezterm_path` on SSH mux domains |
| **startup.lua** | Workspace initialization | Creates vpns + depot workspaces on launch (optional) |

## Platform Detection

### Detection Flow

```
wezterm.target_triple
├── contains "windows"  → check USERDOMAIN env var
│   ├── "MIAMIHOLDINGS" → Work Windows (cmd.exe + msys2, work SSH paths)
│   └── other           → Home Windows (cmd.exe + msys2 ucrt64, home SSH paths)
├── contains "darwin"   → macOS (system bash, Homebrew paths)
├── contains "linux"    → Linux/Ubuntu (system bash, same nodes as macOS)
└── other               → fallback (basic config)
```

### Platform-Specific Node Groups

**Home/macOS/Linux:**
- **VPN Nodes**: `^vpn%d*$` (vpn, vpn2, vpn3)
- **Depot Nodes**: `rd`, `rd2`, `bala`, `venky`, `mikelee`
- **Other Hosts**: `what`, `imac-ubuntu`

**Work Windows:**
- **Prod Gateway**: `^[cn]%d+$` (c1, c2, n1, n2)
- **BDS Workstations**: `^bds%d+$` (bds16, bds17)

Add or modify node groups in `nodes_config.lua` → `get_group_config()`.

## SSH Config Integration

`nodes_config.lua` auto-discovers SSH hosts from `~/.ssh/config`:

1. **Reads** `~/.ssh/config`, following `Include` directives recursively
2. **Extracts** `Host` entries (ignores wildcards like `Host *`)
3. **Groups** hosts using patterns or explicit lists from `get_group_config()`
4. **Populates** launch menu and workspace tabs on startup

### Adding a New SSH Node

1. Add a `Host` block to `~/.ssh/config` (or in `~/.ssh/config.d/` if using Includes):
   ```
   Host mynode
     HostName example.com
     User govardha
   ```

2. If it doesn't match an existing group pattern, add it to `get_group_config()`:
   ```lua
   -- In nodes_config.lua
   explicit_hosts = { "mynode", ... }
   ```

3. Reload WezTerm — the node appears in the launch menu under its group.

### SSH Config Best Practices

See `docs/ssh-config-guide.md` for recommended structure using `Include` directives and Tailscale MagicDNS with LAN fallback.

## Keybindings

### Leader: `Ctrl+B`

**Workspaces:**
| Key | Action |
|-----|--------|
| `Ctrl+B $` | Rename workspace |
| `Ctrl+B s` | Select workspace (fuzzy) |
| `Ctrl+B (` / `)` | Previous/next workspace |

**Tabs:**
| Key | Action |
|-----|--------|
| `Ctrl+B c` | New tab |
| `Ctrl+B ,` | Rename tab |
| `Ctrl+B &` | Close tab |
| `Ctrl+B p` / `n` | Previous/next tab |
| `Ctrl+B 1-9` | Switch to tab N |

**Panes:**
| Key | Action |
|-----|--------|
| `Ctrl+B %` | Split horizontal |
| `Ctrl+B "` | Split vertical |
| `Ctrl+B arrow keys` | Navigate panes |
| `Ctrl+B z` | Toggle zoom pane |
| `Ctrl+B x` | Close pane |

**Other:**
| Key | Action |
|-----|--------|
| `Ctrl+B [` | Enter copy mode (vim keys) |
| `Ctrl+B Space` | Quick select mode |
| `Alt+L` | Show launcher menu |
| `Ctrl+Shift+P` | Command palette |

## Common Tasks

### Modify Appearance

Edit `modules/appearance.lua`:
- **Colors**: Change color scheme (lookup wezterm color palettes)
- **Font**: Edit `font_size` and `font` table
- **Window**: Adjust padding, opacity, scrollback lines

### Update Node Groups

Edit `nodes_config.lua` → `get_group_config()`:

```lua
-- Add pattern-based group:
if M.detect_environment().is_home_linux or M.detect_environment().is_macos then
  return {
    vpn = { pattern = "^vpn%d*$" },
    new_group = { pattern = "^newprefix%d*$" },  -- New group
    explicit_hosts = { "custom1", "custom2" },
  }
end
```

### Test Configuration Changes

Reload WezTerm:
- **macOS/Linux**: `Ctrl+Shift+R` (reload config), or close and reopen
- **Windows**: Close and reopen

Changes to SSH node groups require a full reload. Keybinding changes reload on next key press.

### Add a New Platform

1. **Detect** the platform in `nodes_config.lua` → `detect_env()`:
   ```lua
   local env = {
     is_my_platform = (target_triple:match("pattern") ~= nil),
   }
   ```

2. **Configure** platform-specific settings in `platform_specific.lua` → `apply()`:
   ```lua
   elseif env.is_my_platform then
     config.default_prog = { "my-shell" }
     config.default_domain = "my-domain"
   end
   ```

3. **Add node groups** in `nodes_config.lua` → `get_group_config()` for this platform

4. **Setup workspaces** in `startup.lua` → `setup_workspaces()` if needed

5. Reload and verify nodes appear in launcher menu.

## Safe Loading Pattern

All modules use `safe_require()` defined in `wezterm.lua`:

```lua
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    wezterm.log_error("Failed to load " .. module .. ": " .. result)
    return {}
  end
  return result
end
```

This prevents a missing or broken module from crashing WezTerm. If a module fails, check the log: `:set-status-left { "level": "error" }` in WezTerm action.

## Conventions

1. **Modular design**: One concern per module
2. **Auto-discovery**: SSH config is the single source of truth
3. **Safe loading**: Use `safe_require()` to load modules
4. **Environment detection**: Use `detect_env()` to branch on OS/hostname
5. **Leader key**: `Ctrl+B` is the primary keybinding prefix (tmux-like)

## Testing Strategy

- **Node grouping**: Verify nodes appear in launcher under correct group (`:Alt+L`)
- **Keybindings**: Open WezTerm, test Ctrl+B combos (workspace, pane, tab management)
- **Platform detection**: Test on each platform (macOS, Linux, Windows) — verify shell, fonts, node groups
- **SSH nodes**: Add a test entry to `~/.ssh/config`, reload, check launcher
- **Startup workspaces**: Verify `vpns` and `depot` workspaces exist on launch (toggle with `Ctrl+B s`)

## Related Documentation

- **README.md** — Installation instructions, directory overview, configuration philosophy
- **docs/ssh-config-guide.md** — SSH config structure with Include directives and Tailscale
- **wezterm.org docs** — Official WezTerm config reference
