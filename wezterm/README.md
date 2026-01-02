# WezTerm Configuration

Modular WezTerm configuration with centralized node management, tmux-style keybindings, and environment-specific settings.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Configuration Files](#configuration-files)
- [Node Management](#node-management)
- [Workspaces](#workspaces)
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
│   ├── nodes_config.lua        # ⭐ Central node/server configuration (auto-parsed from SSH config)
│   ├── platform_specific.lua   # OS-specific settings and launch menu
│   ├── ssh_utils.lua           # SSH domain configuration (currently disabled)
│   └── startup.lua             # 🚀 Auto-workspace creation on launch
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

-- Enable auto-workspace creation (currently disabled)
-- local startup = safe_require("modules.startup")
-- startup.apply(config)
```

#### `modules/nodes_config.lua` ⭐

**Automatically parses your `~/.ssh/config` and organizes nodes into groups.**

Provides three main functions:

- `get_nodes()` - Returns list of nodes based on environment (parsed from SSH config)
- `get_launch_menu_entries()` - Generates launch menu entries
- `spawn_node_tab(window, node)` - Creates a new tab with auto-naming

**Group Configuration (customize in `get_group_config()`):**

For **Home/macOS**:

```lua
{
    label = "--- VPN Nodes ---",
    pattern = "^vpn%d*$",  -- Matches: vpn, vpn2, vpn3, ..., vpn9
}
{
    label = "--- Depot Nodes ---",
    explicit = { "rd", "rd2", "bala", "venky", "mikelee" },
}
```

For **Work Windows**:

```lua
{
    label = "--- Prod GW ---",
    pattern = "^[cn]%d+$",  -- Matches: c1, c2, n1, n2
}
{
    label = "--- BDS Workstations ---",
    pattern = "^bds%d+$",  -- Matches: bds16, bds17, bds18...
}
```

**How It Works:**

1. Reads your `~/.ssh/config` file
2. Extracts all `Host` entries (ignoring wildcards like `i-*`)
3. Groups them using patterns or explicit lists you define
4. Automatically appears in launcher and auto-workspaces

**Adding New Nodes:** Just add to your `~/.ssh/config`:

```ssh-config
Host vpn10
    HostName vpn10.vadai.org
    User ubuntu
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

Reload WezTerm → `vpn10` automatically appears in VPN Nodes group!

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

- **Leader Key**: Ctrl+B (⌃B on macOS) - configured for tmux compatibility
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
- **macOS**: macOS-specific settings, home node entries, Homebrew bash as default shell
- Builds launch menu from `nodes_config.lua`

#### `modules/startup.lua` 🚀

**Auto-workspace creation on launch** (optional, currently disabled by default)

Creates workspaces automatically when WezTerm starts, with SSH connections pre-configured.

**Currently disabled** in `wezterm.lua`. See [Workspaces](#workspaces) section for how to enable and customize.

---

## Node Management

### How Nodes Are Discovered

Nodes are **automatically parsed from your `~/.ssh/config`** file. No hardcoding required!

### Group Patterns

Edit `modules/nodes_config.lua` → `get_group_config()` to customize grouping:

**Pattern Syntax:**
| Pattern | Matches | Example |
|---------|---------|---------|
| `^vpn%d*$` | vpn + optional digits | vpn, vpn2, vpn9 |
| `^vpn%d+$` | vpn + required digits | vpn2, vpn9 (NOT vpn) |
| `^bds%d+$` | bds + digits | bds16, bds17 |
| `^[cn]%d+$` | c or n + digits | c1, c2, n1, n2 |
| `depot` | Contains "depot" | rinku-depot, bala-depot |

**Explicit Lists:**

```lua
{
    label = "--- Special Hosts ---",
    explicit = { "what", "imac-ubuntu" },
}
```

### Accessing Nodes

**Method 1: Command Palette** (Always Available)

```
⌃⇧P (Ctrl+Shift+P)    → Opens command palette
Type: "launcher"       → Filters to launcher
Enter                  → Shows your grouped nodes
```

**Method 2: Auto-Workspaces** (If Enabled)

- See [Workspaces](#workspaces) section below

---

## Workspaces

### What Are Workspaces?

Workspaces are **virtual desktop environments** for terminal sessions. Think of them like tmux sessions - each workspace can contain multiple tabs and panes, organized by context.

**Use Cases:**

- **By Environment**: prod, staging, dev workspaces
- **By Project**: project-x, project-y workspaces
- **By Function**: monitoring, deployment, debugging workspaces

**Current Status:** Auto-workspace creation is **disabled by default**. You can create workspaces manually or enable auto-creation.

---

### Manual Workspace Management

#### Creating Workspaces Manually

**Method 1: Command Palette**

```
⌃⇧P                          → Command palette
Type: "Switch To Workspace"  → Select command
Type: "prod"                 → Enter workspace name
Enter                        → Creates and switches to workspace
```

**Method 2: Tmux-Style (Leader Key)**

```
⌃B s     → Shows existing workspaces (select to switch)
⌃B $     → Rename current workspace
⌃B (     → Previous workspace
⌃B )     → Next workspace
```

#### Populating Workspaces Manually

Once in a workspace:

```
⌃⇧P → "launcher" → Select node   # Spawn SSH connection
⌃B c                              # New local tab
⌃B %                              # Split horizontally
⌃B "                              # Split vertically
⌃B ,                              # Rename tab
```

**Example Manual Workflow:**

```bash
# Create prod workspace
⌃⇧P → "Switch To Workspace" → "prod"

# Add tabs
⌃⇧P → "launcher" → "c1"     # Tab 1: c1 gateway
⌃⇧P → "launcher" → "c2"     # Tab 2: c2 gateway
⌃B c                         # Tab 3: local shell
⌃B ,                         # Rename to "local"

# Create dev workspace
⌃⇧P → "Switch To Workspace" → "dev"
# ... add dev nodes ...

# Switch between them
⌃B s → Select "prod" or "dev"
```

---

### Auto-Workspace Creation (Advanced)

**Goal:** Automatically create workspaces with SSH connections on WezTerm startup.

#### Step 1: Enable startup.lua

In `wezterm.lua`, uncomment these lines:

```lua
-- Load modules
local startup = safe_require("modules.startup")  -- UNCOMMENT THIS

-- ... later ...

-- Apply modules to configuration
startup.apply(config)  -- UNCOMMENT THIS
```

#### Step 2: Understand Default Behavior

With `startup.lua` enabled, **one workspace** is created on launch:

**Workspace: "nodes"**

- Tab 1: "local" (your shell)
- Tab 2+: One tab per node from your SSH config (auto-named)

**Example (Home/macOS):**

```
Workspace: nodes
├── [local]        # Local bash shell
├── [vpn]          # ssh vpn
├── [vpn2]         # ssh vpn2
├── [vpn3]         # ssh vpn3
├── [rd]           # ssh rd
├── [rd2]          # ssh rd2
├── [what]         # ssh what
└── [imac-ubuntu]  # ssh imac-ubuntu
```

#### Step 3: Customize Multiple Workspaces

To create **multiple workspaces** with specific nodes, edit `modules/startup.lua`:

**Example: Create "vpn" and "depot" workspaces**

```lua
function M.setup_workspaces(env_info)
	local is_macos = env_info.is_home_osx
	local is_home_windows = env_info.is_home_windows
	local is_work_windows = env_info.is_work_windows

	-- Get all nodes
	local all_nodes = nodes_config.get_nodes()

	if is_macos or is_home_windows then
		-- Create VPN workspace
		local _, _, vpn_window = mux.spawn_window({
			workspace = "vpn",
			args = is_home_windows and {
				"cmd.exe",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			} or nil,
		})
		vpn_window:active_tab():set_title("local")

		-- Add only VPN nodes
		for _, node in ipairs(all_nodes) do
			if not node.separator and node.name:match("^vpn%d*$") then
				nodes_config.spawn_node_tab(vpn_window, node)
			end
		end

		-- Create Depot workspace
		local _, _, depot_window = mux.spawn_window({
			workspace = "depot",
			args = is_home_windows and {
				"cmd.exe",
				"/k",
				"C:\\Apps\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			} or nil,
		})
		depot_window:active_tab():set_title("local")

		-- Add depot nodes
		local depot_names = { "rd", "rd2", "bala", "venky", "mikelee" }
		for _, node in ipairs(all_nodes) do
			if not node.separator then
				for _, depot_name in ipairs(depot_names) do
					if node.name == depot_name then
						nodes_config.spawn_node_tab(depot_window, node)
						break
					end
				end
			end
		end

		-- Set active workspace
		mux.set_active_workspace("vpn")
		vpn_window:gui_window():set_position(200, 100)

	elseif is_work_windows then
		-- Work: Create "prod" workspace with gateway nodes
		local _, _, prod_window = mux.spawn_window({
			workspace = "prod",
			args = {
				"cmd.exe",
				"/k",
				"C:\\DevSoftware\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash",
			},
		})
		prod_window:active_tab():set_title("local")

		-- Add only prod gateway nodes (c1, c2, n1, n2)
		for _, node in ipairs(all_nodes) do
			if not node.separator and node.name:match("^[cn]%d+$") then
				nodes_config.spawn_node_tab(prod_window, node)
			end
		end

		mux.set_active_workspace("prod")
		prod_window:gui_window():set_position(200, 100)
	end
end
```

**Result:**

- **Home/macOS**: Two workspaces ("vpn" with VPN nodes, "depot" with depot nodes)
- **Work**: One workspace ("prod" with c1, c2, n1, n2)

#### Step 4: Pattern-Based Filtering

Use Lua patterns to filter nodes dynamically:

```lua
-- Only nodes matching pattern
for _, node in ipairs(all_nodes) do
	if not node.separator and node.name:match("^vpn%d*$") then
		-- Matches: vpn, vpn2, vpn3, etc.
		nodes_config.spawn_node_tab(window, node)
	end
end

-- Specific node names
local target_nodes = { "rd", "rd2", "bala" }
for _, node in ipairs(all_nodes) do
	if not node.separator then
		for _, target in ipairs(target_nodes) do
			if node.name == target then
				nodes_config.spawn_node_tab(window, node)
				break
			end
		end
	end
end

-- Nodes containing substring
for _, node in ipairs(all_nodes) do
	if not node.separator and node.name:match("depot") then
		-- Matches: rinku-depot, bala-depot, etc.
		nodes_config.spawn_node_tab(window, node)
	end
end
```

#### Step 5: Window Positioning

Position multiple workspace windows:

```lua
-- VPN workspace window
vpn_window:gui_window():set_position(200, 100)

-- Depot workspace window (doesn't auto-show, just positioned)
depot_window:gui_window():set_position(800, 100)

-- Set which one shows first
mux.set_active_workspace("vpn")
```

---

### Workspace Best Practices

**1. Don't Create Too Many Auto-Workspaces**

- 2-3 workspaces max on startup
- Create others manually as needed

**2. Group by Context, Not by Node**

- Good: "prod", "dev", "monitoring"
- Bad: "c1", "c2", "n1" (use tabs instead)

**3. Use Descriptive Names**

```
⌃B $  → Rename workspace to "prod-troubleshooting"
⌃B ,  → Rename tab to "c1-logs"
```

**4. Workspace Persistence**

- Workspaces persist between sessions (until all windows closed)
- Close all tabs in workspace → workspace removed

**5. Switching is Fast**

```
⌃B s  → Quick fuzzy search through workspaces
Type: "pro"
Enter → Switches to "prod" workspace
```

---

### Workspace Patterns

**Pattern 1: Environment-Based**

```
Workspaces:
├── prod     → c1, c2, n1, n2
├── staging  → staging nodes
└── dev      → dev nodes
```

**Pattern 2: Function-Based**

```
Workspaces:
├── ssh      → All SSH connections
├── local    → Local development
└── logs     → Monitoring dashboards
```

**Pattern 3: Project-Based**

```
Workspaces:
├── project-x   → project-x dev/staging/prod
├── project-y   → project-y environments
└── oncall      → On-call dashboards/alerts
```

---

## Keybindings

### Standard WezTerm Bindings

| Key   | Action            |
| ----- | ----------------- |
| `⌃⇧P` | Command palette   |
| `⌃⇧T` | New tab           |
| `⌃⇧W` | Close current tab |

_(⌃ = Control on macOS)_

### Tmux-Style Bindings (wez-tmux plugin)

**Leader Key**: `⌃B` (Control+B)

#### Workspaces

| Key    | Action                          |
| ------ | ------------------------------- |
| `⌃B $` | Rename workspace                |
| `⌃B s` | Select workspace (fuzzy picker) |
| `⌃B (` | Previous workspace              |
| `⌃B )` | Next workspace                  |

#### Tabs

| Key      | Action                        |
| -------- | ----------------------------- |
| `⌃B c`   | Create new tab                |
| `⌃B ,`   | Rename tab                    |
| `⌃B &`   | Close tab (with confirmation) |
| `⌃B p`   | Previous tab                  |
| `⌃B n`   | Next tab                      |
| `⌃B l`   | Last active tab               |
| `⌃B 1-9` | Switch to tab N               |

#### Panes (Splits)

| Key           | Action                         |
| ------------- | ------------------------------ |
| `⌃B %`        | Split horizontally             |
| `⌃B "`        | Split vertically               |
| `⌃B {`        | Rotate panes counter-clockwise |
| `⌃B }`        | Rotate panes clockwise         |
| `⌃B ←/→/↑/↓`  | Navigate panes                 |
| `⌃B q`        | Pane selection mode            |
| `⌃B z`        | Toggle pane zoom               |
| `⌃B !`        | Move pane to new tab           |
| `⌃B x`        | Close pane (with confirmation) |
| `⌃B ⌃←/→/↑/↓` | Resize pane (5 cells)          |

#### Copy Mode

| Key       | Action                                 |
| --------- | -------------------------------------- |
| `⌃B [`    | Enter copy mode                        |
| `Escape`  | Clear selection / Clear pattern / Exit |
| `v`       | Cell selection                         |
| `⇧V`      | Line selection                         |
| `⌃V`      | Block selection                        |
| `h/j/k/l` | Vim-style navigation                   |
| `w/b/e`   | Word navigation                        |
| `0/$`     | Line start/end                         |
| `g/G`     | Top/bottom of scrollback               |
| `⌃B`      | Page up                                |
| `⌃F`      | Page down                              |
| `⌃U`      | Half page up                           |
| `⌃D`      | Half page down                         |
| `/`       | Search forward                         |
| `?`       | Search backward                        |
| `n/N`     | Next/previous match                    |
| `y`       | Copy and exit                          |

#### Misc

| Key        | Action            |
| ---------- | ----------------- |
| `⌃B Space` | Quick select mode |
| `⌃B ⌃B`    | Send ⌃B to shell  |

---

## Environment Detection

Configuration automatically detects:

### Windows

- **Work**: `USERDOMAIN == "WORKDOMAIN"`
  - Uses `C:/DevSoftware/msys64/usr/bin/ssh.exe`
  - Loads work nodes from SSH config (gateways, BDS workstations)
  - Custom work background image
- **Home**: All other Windows environments
  - Uses `C:/Apps/msys64/usr/bin/ssh.exe`
  - Loads home nodes from SSH config (VPN servers, depot)

### macOS

- Uses system `ssh` (or Homebrew ssh if in PATH)
- Uses Homebrew bash as default shell: `/opt/homebrew/bin/bash`
- Loads home nodes from SSH config (VPN servers, depot)
- Uses 1Password SSH agent for passwordless authentication

### Authentication

**Home/macOS:**

- 1Password SSH Agent (configured in `~/.ssh/config`)
- Passwordless authentication via SSH keys stored in 1Password

**Work:**

- Traditional SSH keys or password authentication
- No 1Password support

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

### Customize Node Groups

Edit `modules/nodes_config.lua` → `get_group_config()`:

```lua
-- Add a new group
{
    label = "--- My Custom Group ---",
    pattern = "^mypattern%d+$",  -- or use explicit list
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

**Note**: This will show ALL hosts from `~/.ssh/config` in Command Palette.

---

## Troubleshooting

### Launch Menu Shows Too Many Hosts

**Problem**: Command palette shows many extra hosts from SSH config

**Solution**: Ensure this line is commented in `wezterm.lua`:

```lua
-- config.ssh_domains = wezterm.default_ssh_domains()
```

### Nodes Not Appearing

**Problem**: Launch menu empty or missing nodes

**Checklist**:

1. Verify nodes exist in `~/.ssh/config`
2. Check patterns in `nodes_config.lua` → `get_group_config()`
3. Reload WezTerm configuration

### Startup Auto-Tabs Not Working

**Problem**: No tabs auto-created on launch

**Solution**: Uncomment in `wezterm.lua`:

```lua
local startup = safe_require("modules.startup")
startup.apply(config)
```

### Wrong Bash Version (macOS)

**Problem**: `bash --version` shows 3.2.57 instead of 5.3+

**Solution**: Add to top of `~/.bashrc`:

```bash
# Setup Homebrew PATH
eval "$(/opt/homebrew/bin/brew shellenv)"
```

And verify `platform_specific.lua` has:

```lua
config.default_prog = { "/opt/homebrew/bin/bash", "-l" }
```

### SSH Connection Fails

**Problem**: Tab opens but connection fails

**Checklist**:

1. Test SSH from command line: `ssh <node-alias>`
2. Verify node exists in `~/.ssh/config`
3. Check SSH keys (1Password on macOS, ssh-add on other systems)
4. Verify firewall/VPN connectivity

### Workspaces Not Persisting

**Problem**: Workspaces disappear on restart

**Cause**: Workspaces are removed when all tabs are closed

**Solution**: Keep at least one tab open in each workspace you want to preserve

### Tab Titles Not Auto-Naming

**Problem**: Tabs show hostname instead of configured name

**Solution**: Verify using `nodes_config.spawn_node_tab()` instead of manual spawn

### "switcher: command not found" (macOS)

**Problem**: Error when starting bash

**Solution**: Add to `~/.bashrc`:

```bash
# Only load switcher if it exists
if command -v switcher &> /dev/null; then
    source <(switcher init bash)
fi
```

---

## Quick Start Guide

### First Time Setup

1. **Clone this repo to `~/.config/wezterm/`**

```bash
   git clone <repo-url> ~/.config/wezterm
```

2. **Ensure your SSH config is set up**

```bash
   vi ~/.ssh/config
   # Add your hosts with proper formatting
```

3. **Customize node groups** (optional)

```bash
   vi ~/.config/wezterm/modules/nodes_config.lua
   # Edit get_group_config() to match your node naming
```

4. **Launch WezTerm**
   - Nodes auto-populate from SSH config
   - Use Command Palette (`⌃⇧P` → "launcher") to access

5. **Enable auto-workspaces** (optional)

```bash
   vi ~/.config/wezterm/wezterm.lua
   # Uncomment startup lines
```

### Daily Workflow

**Creating Contexts:**

```
⌃⇧P → "Switch To Workspace" → "prod"    # Create prod workspace
⌃⇧P → "launcher" → select nodes          # Add SSH connections
⌃B c                                      # Add local tabs
⌃B ,                                      # Rename tabs
```

**Switching Contexts:**

```
⌃B s     → Quick workspace switcher
⌃B ( )   → Previous/Next workspace
```

**Managing Tabs:**

```
⌃B 1-9   → Jump to tab
⌃B c     → New tab
⌃B ,     → Rename tab
```

---

## Configuration Philosophy

This setup follows these principles:

1. **Auto-Discovery**: Nodes parsed from SSH config, not hardcoded
2. **Pattern-Based**: Group nodes by naming conventions
3. **Single Source of Truth**: SSH config is the source, WezTerm reflects it
4. **Modular Design**: Each module handles one concern
5. **Environment Aware**: Automatically adapts to work/home and OS
6. **Keyboard Driven**: Tmux-style bindings for efficient workflow
7. **Safe Loading**: `safe_require()` prevents crashes from missing modules

---

## References

- [WezTerm Documentation](https://wezfurlong.org/wezterm/)
- [wez-tmux Plugin](https://github.com/sei40kr/wez-tmux)
- [Catppuccin Color Scheme](https://github.com/catppuccin/wezterm)
- [Lua Pattern Reference](https://www.lua.org/manual/5.1/manual.html#5.4.1)

---

**Last Updated**: January 2026
