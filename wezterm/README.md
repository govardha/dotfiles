# WezTerm Configuration

Modular WezTerm configuration with auto-discovered SSH nodes, tmux-style keybindings, and per-platform environment detection. Supports macOS, Windows (home/work), and Linux (Ubuntu 24/26).

## Directory Structure

```
~/.config/wezterm/
├── wezterm.lua                 # Entry point — loads all modules via safe_require()
├── modules/
│   ├── appearance.lua          # Colors, fonts, window chrome, scrollback
│   ├── format.lua              # Tab title format and right-status bar (clock)
│   ├── keybindings.lua         # Leader key (Ctrl+B) and custom bindings
│   ├── misc.lua                # Paste newline canonicalization
│   ├── mouse.lua               # Triple-click select, right-click copy/paste
│   ├── nodes_config.lua        # SSH config parser, node grouping, launch menu
│   ├── platform_specific.lua   # OS/environment detection, per-platform launch menu
│   ├── ssh_utils.lua           # SSH mux domain remote_wezterm_path config
│   └── startup.lua             # Auto-workspace creation on gui-startup
├── plugins/
│   └── wez-tmux/               # Tmux-style keybindings plugin (Ctrl+B leader)
│       └── plugin/init.lua
├── docs/
│   └── ssh-config-guide.md     # SSH config structure with Include + Tailscale
├── DockerFile                  # Build WezTerm from source (CentOS Stream 8)
└── BUILD-README.md             # Docker build instructions
```

## Module Reference

| Module | Purpose |
|--------|---------|
| `appearance.lua` | Everforest Dark Hard color scheme, JetBrains Mono 12pt, custom tab bar colors, window padding, transparency, 10k scrollback |
| `format.lua` | Active tab: purple bg + terminal icon. Inactive tab: black bg. Right status: clock with date/time |
| `keybindings.lua` | Leader key `Ctrl+B`, loads wez-tmux plugin, `Alt+L` for launcher, `Leader+,` to rename tab |
| `misc.lua` | `canonicalize_pasted_newlines = "CarriageReturn"` for tmux compatibility |
| `mouse.lua` | Triple-click selects semantic zone, right-click copies selection or pastes |
| `nodes_config.lua` | Parses `~/.ssh/config` (follows `Include` directives), groups hosts by pattern/explicit list, generates launch menu entries |
| `platform_specific.lua` | Detects OS via `wezterm.target_triple`, sets platform-specific shell, font, and launch menu |
| `ssh_utils.lua` | Sets `remote_wezterm_path` on SSH mux domains for vpn/depot/what nodes |
| `startup.lua` | Creates vpns + depot workspaces with SSH tabs on launch (optional, enabled in `wezterm.lua`) |

## Platform Support

| Platform | `target_triple` | Detection | Shell | Notes |
|----------|-----------------|-----------|-------|-------|
| macOS | `aarch64-apple-darwin` / `x86_64-apple-darwin` | Direct match | System bash | 1Password SSH agent, Homebrew paths |
| Windows (Work) | `x86_64-pc-windows-msvc` | `USERDOMAIN == "MIAMIHOLDINGS"` | cmd.exe + msys2 | Work SSH paths, legacy gateway entries |
| Windows (Home) | `x86_64-pc-windows-msvc` | All other Windows | cmd.exe + msys2 ucrt64 | Home SSH paths, nodes from SSH config |
| Linux/Ubuntu | `x86_64-unknown-linux-gnu` | `target_triple:match("linux")` | System bash | Same node groups as macOS |

### Detection Flow

```
wezterm.target_triple
├── contains "windows"  → check USERDOMAIN → Work or Home Windows
├── contains "darwin"   → macOS
├── contains "linux"    → Linux/Ubuntu
└── other               → fallback (no platform-specific config)
```

## SSH Config Integration

`nodes_config.lua` auto-discovers hosts from `~/.ssh/config`:

1. Reads the config file, following `Include` directives recursively
2. Extracts `Host` entries (skips wildcards like `Host *`)
3. Groups hosts using patterns or explicit lists defined in `get_group_config()`
4. Populates the launch menu and workspace tabs

### Node Groups (Home/macOS/Linux)

| Group | Pattern/List | Examples |
|-------|-------------|----------|
| VPN Nodes | `^vpn%d*$` | vpn, vpn2, vpn3 |
| Depot Nodes | explicit: `rd`, `rd2`, `bala`, `venky`, `mikelee` | — |
| Other Hosts | explicit: `what`, `imac-ubuntu` | — |

### Node Groups (Work Windows)

| Group | Pattern | Examples |
|-------|---------|----------|
| Prod GW | `^[cn]%d+$` | c1, c2, n1, n2 |
| BDS Workstations | `^bds%d+$` | bds16, bds17 |

See [docs/ssh-config-guide.md](docs/ssh-config-guide.md) for the recommended SSH config structure using `Include` directives and Tailscale MagicDNS with LAN fallback.

## Adding a New Node

1. Add a `Host` block to `~/.ssh/config` (or a file in `~/.ssh/config.d/` if using Includes)
2. If it doesn't match an existing group pattern, add it to the explicit list in `nodes_config.lua` → `get_group_config()`
3. Reload WezTerm — the node appears in the launch menu

## Adding a New Platform

1. Add detection in `nodes_config.lua` → `detect_env()` (new `is_*` flag)
2. Add an `elseif` branch in `platform_specific.lua` → `M.apply()`
3. Add workspace setup in `startup.lua` → `detect_environment()` and `setup_workspaces()`
4. Update `get_group_config()` if the platform needs different node groups

## Keybindings

### Leader Key: `Ctrl+B`

**Workspaces:**
| Key | Action |
|-----|--------|
| `Ctrl+B $` | Rename workspace |
| `Ctrl+B s` | Select workspace (fuzzy) |
| `Ctrl+B (` | Previous workspace |
| `Ctrl+B )` | Next workspace |

**Tabs:**
| Key | Action |
|-----|--------|
| `Ctrl+B c` | New tab |
| `Ctrl+B ,` | Rename tab |
| `Ctrl+B &` | Close tab |
| `Ctrl+B p/n` | Previous/next tab |
| `Ctrl+B 1-9` | Switch to tab N |

**Panes:**
| Key | Action |
|-----|--------|
| `Ctrl+B %` | Split horizontal |
| `Ctrl+B "` | Split vertical |
| `Ctrl+B arrows` | Navigate panes |
| `Ctrl+B z` | Toggle zoom |
| `Ctrl+B x` | Close pane |

**Other:**
| Key | Action |
|-----|--------|
| `Ctrl+B [` | Enter copy mode (vim keys) |
| `Ctrl+B Space` | Quick select mode |
| `Alt+L` | Show launcher |
| `Ctrl+Shift+P` | Command palette |

## Installation

### macOS

```bash
# Install WezTerm (via Homebrew or download from wezterm.org)
brew install --cask wezterm

# Symlink config
ln -sf ~/src/dotfiles/wezterm ~/.config/wezterm

# Install JetBrains Mono
brew install --cask font-jetbrains-mono
```

### Linux/Ubuntu

```bash
# Install WezTerm (via ansible playbook or manually from wezterm.org)
# See: https://wezterm.org/install/linux.html

# Symlink config
ln -sf ~/src/dotfiles/wezterm ~/.config/wezterm

# Install JetBrains Mono
sudo apt install fonts-jetbrains-mono
```

### Windows

```
# Clone/copy to config location
# WezTerm looks for: %USERPROFILE%\.config\wezterm\wezterm.lua
mklink /D %USERPROFILE%\.config\wezterm C:\path\to\dotfiles\wezterm
```

## Configuration Philosophy

1. **Auto-Discovery** — Nodes parsed from SSH config, not hardcoded
2. **Single Source of Truth** — SSH config is the source, WezTerm reflects it
3. **Modular** — Each module handles one concern
4. **Environment Aware** — Adapts to work/home and OS automatically
5. **Safe Loading** — `safe_require()` prevents crashes from missing modules
