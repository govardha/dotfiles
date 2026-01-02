# WezTerm Configuration

Modular WezTerm configuration with centralized node management, tmux-style keybindings, and environment-specific settings.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Configuration Files](#configuration-files)
- [Node Management](#node-management)
- [Keybindings](#keybindings)
- [Environment Detection](#environment-detection)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Directory Structure

```
~/.config/wezterm/
├── wezterm.lua                 # Main entry point - loads all modules
├── modules/                    # Configuration modules
│   ├── appearance.lua          # Colors, fonts, window styling
│   ├── format.lua              # Tab formatting and status bar
│   ├── keybindings.lua         # Custom keybindings and leader key
│   ├── misc.lua                # Miscellaneous settings (paste behavior, etc.)
│   ├── mouse.lua               # Mouse bindings (triple-click, right-click)
│   ├── nodes_config.lua        # ⭐ Central node/server configuration
│   ├── platform_specific.lua   # OS-specific settings and launch menu
│   ├── ssh_utils.lua           # SSH domain configuration (currently disabled)
│   └── startup.lua             # Auto-workspace creation on launch
└── plugins/
    └── wez-tmux/               # Tmux-style keybindings plugin
        └── plugin/
            └── init.lua        # Modified to use Ctrl+B as leader
```

---

## Configuration Files

### Core Files

#### `wezterm.lua`

Main configuration file that:

- Loads all modules using `safe_require()`
- Initializes SSH domains (currently disabled to prevent auto-loading from `~/.ssh/config`)
- Applies module configurations in order

**Key Setting:**

```lua
-- Disabled to prevent SSH config auto-discovery
-- config.ssh_domains = wezterm.default_ssh_domains()
```

#### `modules/nodes_config.lua` ⭐

**Single source of truth for all SSH nodes/servers.**

Provides three main functions:

- `get_nodes()` - Returns list of nodes based on environment
- `get_launch_menu_entries()` - Generates launch menu entries
- `spawn_node_tab(window, node)` - Creates a new tab with auto-naming

**Node Structure:**

```lua
{
    name = "vpn",                           -- Display name (becomes tab title)
    host = "vpn.pigeon-hamlet.ts.net",      -- Hostname or IP
    user = "ubuntu",                         -- SSH username
    ssh_cmd = "/path/to/ssh"                -- SSH executable path
}

-- Separators:
{ label = "--- VPN Nodes ---", separator = true }
```

**Environment-Specific Nodes:**

- **Work Windows**: Production gateway nodes (c1, c2, n1, n2) + BDS workstations
- **Home Windows/macOS**: VPN servers + Depot nodes

---

### Module Details

#### `modules/appearance.lua`

Visual configuration:

- **Color Scheme**: Catppuccin Mocha
- **Font**: JetBrains Mono, 11pt
- **Background**: Semi-transparent with horizontal gradient (black → midnight blue)
- **Tab Bar**: Fancy tab bar with custom window control icons
- **Scrollback**: 10,000 lines

#### `modules/format.lua`

Tab and status bar formatting:

- **Active Tab**: Purple background with terminal icon + tab number
- **Inactive Tab**: Black background with tab number only
- **Right Status**: Clock icon + date/time (format: `Mon Jan 02 2026 14:30:45`)

#### `modules/keybindings.lua`

Custom keybindings:

- **Alt+L**: Show launcher menu
- **Leader+,**: Rename current tab
- **Leader Key**: Ctrl+B (configured for tmux compatibility)
- Loads wez-tmux plugin for tmux-style bindings

#### `modules/misc.lua`

Miscellaneous settings:

- **Paste Behavior**: Converts newlines to `\r` (Carriage Return) for better tmux/shell compatibility

#### `modules/mouse.lua`

Mouse interactions:

- **Triple-click**: Select semantic zone
- **Right-click**: Copy selection if text is selected, otherwise paste

#### `modules/platform_specific.lua`

OS and environment-specific configuration:

- **Work Windows**: Custom background, msys2 shell paths, work node entries
- **Home Windows**: Home shell paths, home node entries
- **macOS**: macOS-specific settings, home node entries
- Builds launch menu from `nodes_config.lua`

#### `modules/startup.lua`

Auto-workspace creation on launch (optional):

- Creates a "nodes" workspace
- First tab: "local" (bash shell)
- Subsequent tabs: One per node from `nodes_config.lua`, auto-named
- **Currently disabled** in `wezterm.lua` (commented out)

**To enable auto-workspaces**, uncomment in `wezterm.lua`:

```lua
local startup = safe_require("modules.startup")
-- ...
startup.apply(config)
```

---

## Node Management

### Adding New Nodes

Edit `modules/nodes_config.lua` in the appropriate environment section:

```lua
-- Example: Adding a new work node
if env.is_work_windows then
    -- Existing nodes...

    table.insert(nodes, {
        name = "bds16",
        host = "bds16.your-domain.com",
        user = os.getenv("USERNAME"),
        ssh_cmd = ssh_cmd
    })
end
```

### Node Display Order

Nodes appear in **launch menu** and **auto-created tabs** in the exact order they're added to the `nodes` table in `nodes_config.lua`.

### Accessing Nodes

Two methods:

1. **Launch Menu** (Alt+L):
   - Shows all nodes from `nodes_config.lua`
   - Opens connection in current tab or new tab
   - Tabs are auto-named with node name

2. **Auto-Workspace** (startup.lua - if enabled):
   - Creates tabs for all nodes on WezTerm launch
   - First tab: "local" shell
   - Rest: One tab per node, auto-named

---

## Keybindings

### Standard WezTerm Bindings

| Key            | Action             |
| -------------- | ------------------ |
| `Alt+L`        | Open launcher menu |
| `Ctrl+Shift+P` | Command palette    |
| `Ctrl+Shift+T` | New tab            |
| `Ctrl+Shift+W` | Close current tab  |

### Tmux-Style Bindings (wez-tmux plugin)

**Leader Key**: `Ctrl+B` (modified from default)

#### Workspaces

| Key        | Action                          |
| ---------- | ------------------------------- |
| `Ctrl+B $` | Rename workspace                |
| `Ctrl+B s` | Select workspace (fuzzy picker) |
| `Ctrl+B (` | Previous workspace              |
| `Ctrl+B )` | Next workspace                  |

#### Tabs

| Key          | Action                        |
| ------------ | ----------------------------- |
| `Ctrl+B c`   | Create new tab                |
| `Ctrl+B ,`   | Rename tab                    |
| `Ctrl+B &`   | Close tab (with confirmation) |
| `Ctrl+B p`   | Previous tab                  |
| `Ctrl+B n`   | Next tab                      |
| `Ctrl+B l`   | Last active tab               |
| `Ctrl+B 1-9` | Switch to tab N               |

#### Panes (Splits)

| Key              | Action                         |
| ---------------- | ------------------------------ |
| `Ctrl+B %`       | Split horizontally             |
| `Ctrl+B "`       | Split vertically               |
| `Ctrl+B {`       | Rotate panes counter-clockwise |
| `Ctrl+B }`       | Rotate panes clockwise         |
| `Ctrl+B ←/→/↑/↓` | Navigate panes                 |
| `Ctrl+B q`       | Pane selection mode            |
| `Ctrl+B z`       | Toggle pane zoom               |
| `Ctrl+B !`       | Move pane to new tab           |
| `Ctrl+B x`       | Close pane (with confirmation) |
| `Ctrl+B Ctrl+←`  | Resize pane left (5 cells)     |
| `Ctrl+B Ctrl+→`  | Resize pane right (5 cells)    |
| `Ctrl+B Ctrl+↑`  | Resize pane up (5 cells)       |
| `Ctrl+B Ctrl+↓`  | Resize pane down (5 cells)     |

#### Copy Mode

| Key        | Action                                 |
| ---------- | -------------------------------------- |
| `Ctrl+B [` | Enter copy mode                        |
| `Escape`   | Clear selection / Clear pattern / Exit |
| `v`        | Cell selection                         |
| `Shift+V`  | Line selection                         |
| `Ctrl+V`   | Block selection                        |
| `h/j/k/l`  | Vim-style navigation                   |
| `w/b/e`    | Word navigation                        |
| `0/$`      | Line start/end                         |
| `g/G`      | Top/bottom of scrollback               |
| `Ctrl+B`   | Page up                                |
| `Ctrl+F`   | Page down                              |
| `Ctrl+U`   | Half page up                           |
| `Ctrl+D`   | Half page down                         |
| `/`        | Search forward                         |
| `?`        | Search backward                        |
| `n/N`      | Next/previous match                    |
| `y`        | Copy and exit                          |

#### Misc

| Key             | Action               |
| --------------- | -------------------- |
| `Ctrl+B Space`  | Quick select mode    |
| `Ctrl+B Ctrl+B` | Send Ctrl+B to shell |

---

## Environment Detection

Configuration automatically detects:

### Windows

- **Work**: `USERDOMAIN == "WORKDOMAIN"`
  - Uses `C:/DevSoftware/msys64/usr/bin/ssh.exe`
  - Loads work nodes (gateways, BDS workstations)
  - Custom work background image
- **Home**: All other Windows environments
  - Uses `C:/Apps/msys64/usr/bin/ssh.exe`
  - Loads home nodes (VPN servers, depot)

### macOS

- Uses system `ssh`
- Loads home nodes (VPN servers, depot)

---

## Customization

### Change Color Scheme

Edit `modules/appearance.lua`:

```lua
config.color_scheme = "Catppuccin Mocha"  -- Change to any WezTerm color scheme
```

### Change Font

Edit `modules/appearance.lua`:

```lua
config.font = wezterm.font("JetBrains Mono")  -- Change to any installed font
config.font_size = 11.0  -- Adjust size
```

### Change Leader Key

Edit `modules/keybindings.lua`:

```lua
config.leader = { key = "b", mods = "CTRL" }  -- Change key or modifier
```

### Add Custom Keybindings

Edit `modules/keybindings.lua`, add to `config.keys`:

```lua
{
    key = "t",
    mods = "ALT",
    action = act.SpawnTab("CurrentPaneDomain")
}
```

### Disable Auto-Workspaces

In `wezterm.lua`, keep these lines commented:

```lua
-- local startup = safe_require("modules.startup")
-- startup.apply(config)
```

### Enable SSH Config Auto-Discovery

In `wezterm.lua`, uncomment:

```lua
config.ssh_domains = wezterm.default_ssh_domains()
```

**Note**: This will show ALL hosts from `~/.ssh/config` in the Command Palette.

---

## Troubleshooting

### Launch Menu Shows Too Many Hosts

**Problem**: `Ctrl+Shift+P` shows many extra hosts from SSH config

**Solution**: Ensure this line is commented in `wezterm.lua`:

```lua
-- config.ssh_domains = wezterm.default_ssh_domains()
```

### Nodes Not Appearing

**Problem**: Launch menu empty or missing nodes

**Checklist**:

1. Verify `modules/nodes_config.lua` exists
2. Check node definitions for your environment in `get_nodes()`
3. Reload WezTerm configuration

### Startup Auto-Tabs Not Working

**Problem**: No tabs auto-created on launch

**Solution**: Uncomment in `wezterm.lua`:

```lua
local startup = safe_require("modules.startup")
startup.apply(config)
```

### SSH Connection Fails

**Problem**: Tab opens but connection fails

**Checklist**:

1. Verify hostname is correct in `nodes_config.lua`
2. Test SSH from command line: `ssh user@host`
3. Check SSH keys are loaded
4. Verify firewall/VPN connectivity

### Tmux Keybindings Not Working

**Problem**: `Ctrl+B` doesn't trigger tmux-style bindings

**Checklist**:

1. Verify `plugins/wez-tmux/plugin/init.lua` exists
2. Check leader key in `modules/keybindings.lua`:

```lua
   config.leader = { key = "b", mods = "CTRL" }
```

3. Ensure plugin is loaded in `keybindings.lua`:

```lua
   require("plugins.wez-tmux.plugin").apply_to_config(config, {})
```

### Tab Titles Not Auto-Naming

**Problem**: Tabs show hostname instead of configured name

**Solution**: Verify `spawn_node_tab()` is being called (in `startup.lua` or when launching from menu)

### Module Load Errors

**Problem**: Error about missing module

**Solution**: Check file paths:

- All modules should be in `~/.config/wezterm/modules/`
- Plugin should be in `~/.config/wezterm/plugins/wez-tmux/plugin/init.lua`

---

## Configuration Philosophy

This setup follows these principles:

1. **Single Source of Truth**: All nodes defined in `nodes_config.lua`
2. **Modular Design**: Each module handles one concern (appearance, keybindings, etc.)
3. **Environment Aware**: Automatically adapts to work/home and Windows/macOS
4. **Keyboard Driven**: Tmux-style bindings for efficient terminal multiplexing
5. **Safe Loading**: `safe_require()` prevents crashes from missing modules

---

## References

- [WezTerm Documentation](https://wezfurlong.org/wezterm/)
- [wez-tmux Plugin](https://github.com/sei40kr/wez-tmux)
- [Catppuccin Color Scheme](https://github.com/catppuccin/wezterm)

---

**Last Updated**: January 2026
