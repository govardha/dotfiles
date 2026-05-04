# Testing Ubuntu/Linux Support

Testing guide for the `feature/ubuntu-support-and-ssh-config` branch.

## Prerequisites

### 1. Symlink the config

```bash
ln -sf ~/src/dotfiles/wezterm ~/.config/wezterm
```

### 2. Install JetBrains Mono

```bash
sudo apt install fonts-jetbrains-mono
```

### 3. Set up SSH config with Include structure

Back up your existing config:

```bash
cp ~/.ssh/config ~/.ssh/config.bak
```

Create the modular directory:

```bash
mkdir -p ~/.ssh/config.d
```

Add `Include` to the top of `~/.ssh/config` (before any Host blocks):

```bash
# Add this as the FIRST line of ~/.ssh/config
Include ~/.ssh/config.d/*
```

Optionally move host definitions into `~/.ssh/config.d/` files per the structure in [ssh-config-guide.md](ssh-config-guide.md). This is not required — the parser reads both inline hosts and included files.

Verify your hosts are discoverable:

```bash
grep -r "^Host " ~/.ssh/config ~/.ssh/config.d/ 2>/dev/null
```

## Testing

### Test 1: Platform Detection

1. Open WezTerm
2. Press `Ctrl+Shift+P` → type `debug` → select **Show Debug Overlay**
3. Look for: `Detected: Home Linux environment`

- [ ] Pass — log line present

### Test 2: Launch Menu

1. Press `Alt+L` to open the launcher
2. Verify nodes appear grouped:
   - `--- VPN Nodes ---` with vpn, vpn2, vpn3, etc.
   - `--- Depot Nodes ---` with depot hosts
   - `--- Other Hosts ---` with what, imac-ubuntu, etc.

- [ ] Pass — nodes appear and are grouped correctly

### Test 3: Font Rendering

1. Verify the terminal font is JetBrains Mono
2. Check that ligatures and special characters render correctly

- [ ] Pass — JetBrains Mono is active

### Test 4: SSH Connection

1. Press `Alt+L` → select a node you can reach (e.g., a VPN node)
2. Verify the SSH connection succeeds
3. Verify the tab title shows the node name

- [ ] Pass — SSH connects and tab is named correctly

### Test 5: Workspace Auto-Creation (optional)

Only if `startup.apply(config)` is uncommented in `wezterm.lua`:

1. Fully quit and relaunch WezTerm
2. Press `Ctrl+B s` to list workspaces
3. Verify "vpns" and "depot" workspaces exist
4. Switch between them — verify SSH tabs are present

- [ ] Pass — workspaces auto-created with SSH tabs

### Test 6: Include Directive Parsing

Only if you moved hosts into `~/.ssh/config.d/` files:

1. Verify hosts from included files appear in the launcher (`Alt+L`)
2. Compare against: `grep -r "^Host " ~/.ssh/config.d/`

- [ ] Pass — hosts from included files appear in launcher

## If Something Fails

**No nodes in launcher:**
```bash
# Verify SSH config is readable
cat ~/.ssh/config
grep -r "^Host " ~/.ssh/config ~/.ssh/config.d/ 2>/dev/null
```

**Wrong font:**
```bash
# Verify JetBrains Mono is installed
fc-list | grep -i "jetbrains"
```

**No log output:**
- Check WezTerm debug overlay (`Ctrl+Shift+P` → debug) for errors
- Look for `Could not load module` messages

## After Testing

If all tests pass:

```bash
cd ~/src/dotfiles
git add -A
git commit -m "Add Ubuntu/Linux support, Include-aware SSH parser, new README"
git checkout main
git merge feature/ubuntu-support-and-ssh-config
git push
```

If tests fail, stay on the feature branch and fix issues before merging.
