#!/bin/bash

# Airgapped Machine Transfer Script
# This script helps you prepare and transfer your complete Neovim setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to create transfer package
create_transfer_package() {
    local package_dir="nvim-airgapped-$(date +%Y%m%d)"
    local current_dir=$(pwd)
    
    log_step "Creating transfer package: $package_dir"
    
    mkdir -p "$package_dir"
    cd "$package_dir"
    
    # 1. Neovim configuration
    log_info "Copying Neovim configuration..."
    if [[ -d "$HOME/.config/nvim" ]]; then
        cp -r "$HOME/.config/nvim" ./
        log_info "✓ ~/.config/nvim"
    else
        log_warn "✗ ~/.config/nvim not found"
    fi
    
    # 2. Neovim tools (LSPs, formatters, linters)
    log_info "Copying Neovim tools..."
    if [[ -d "$HOME/.local/share/nvim-tools" ]]; then
        cp -r "$HOME/.local/share/nvim-tools" ./
        log_info "✓ ~/.local/share/nvim-tools"
    else
        log_warn "✗ ~/.local/share/nvim-tools not found"
    fi
    
    # 3. Neovim plugins and data
    log_info "Copying Neovim plugins and data..."
    if [[ -d "$HOME/.local/share/nvim" ]]; then
        # Copy everything except mason (which we don't use)
        mkdir -p nvim-share
        cp -r "$HOME/.local/share/nvim"/* nvim-share/ 2>/dev/null || true
        # Remove mason if it exists
        rm -rf nvim-share/mason 2>/dev/null || true
        log_info "✓ ~/.local/share/nvim (excluding mason)"
    else
        log_warn "✗ ~/.local/share/nvim not found"
    fi
    
    # 4. Create installation script for target machine
    cat > install-on-airgapped.sh << 'EOF'
#!/bin/bash

# Installation script for airgapped machine
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check for custom install location
INSTALL_MODE="${1:-system}"
if [[ "$INSTALL_MODE" == "portable" ]]; then
    # Portable mode - install to current directory with SEPARATE config and data dirs
    NVIM_CONFIG_BASE="./nvim-portable/config"
    NVIM_DATA_BASE="./nvim-portable/local"
    NVIM_TOOLS_DIR="./nvim-portable"
    
    log_info "Installing in PORTABLE mode to: ./nvim-portable/"
    log_info "Structure: config/ (XDG_CONFIG_HOME) and local/ (XDG_DATA_HOME)"
    
    mkdir -p "$NVIM_CONFIG_BASE"
    mkdir -p "$NVIM_DATA_BASE"
    mkdir -p "$NVIM_TOOLS_DIR"
else
    # System mode - install to user directories
    NVIM_CONFIG_BASE="$HOME/.config"
    NVIM_DATA_BASE="$HOME/.local/share"
    NVIM_TOOLS_DIR="$HOME/.local/share"
    
    log_info "Installing in SYSTEM mode to user directories"
    
    mkdir -p "$NVIM_CONFIG_BASE"
    mkdir -p "$NVIM_DATA_BASE"
fi

echo "Installing Neovim setup on airgapped machine..."

# Install Neovim configuration
log_step "Installing Neovim configuration..."
if [[ -d "./nvim" ]]; then
    cp -r ./nvim "$NVIM_CONFIG_BASE/"
    log_info "✓ Installed $NVIM_CONFIG_BASE/nvim"
else
    log_warn "✗ nvim directory not found"
fi

# Install Neovim tools
log_step "Installing Neovim tools..."
if [[ -d "./nvim-tools" ]]; then
    cp -r ./nvim-tools "$NVIM_TOOLS_DIR/"
    log_info "✓ Installed $NVIM_TOOLS_DIR/nvim-tools"
else
    log_warn "✗ nvim-tools directory not found"
fi

# Install Neovim plugins and data
log_step "Installing Neovim plugins and data..."
if [[ -d "./nvim-share" ]]; then
    mkdir -p "$NVIM_DATA_BASE/nvim"
    cp -r ./nvim-share/* "$NVIM_DATA_BASE/nvim/" 2>/dev/null || true
    log_info "✓ Installed $NVIM_DATA_BASE/nvim"
else
    log_warn "✗ nvim-share directory not found"
fi

if [[ "$INSTALL_MODE" == "portable" ]]; then
    # Create portable launcher script
    cat > nvim-portable.sh << 'PORTEOF'
#!/bin/bash

# Portable Neovim Launcher
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set XDG directories to portable location (SEPARATE config and data)
export XDG_CONFIG_HOME="$SCRIPT_DIR/nvim-portable/config"
export XDG_DATA_HOME="$SCRIPT_DIR/nvim-portable/local"

# Add tools to PATH
export PATH="$SCRIPT_DIR/nvim-portable/nvim-tools/bin:$PATH"

# Launch Neovim
exec nvim "$@"
PORTEOF
    
    chmod +x nvim-portable.sh
    
    # Create test script for portable mode
    cat > test-portable.sh << 'TESTEOF'
#!/bin/bash

# Test script for portable Neovim setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing portable Neovim setup..."

# Set environment (SEPARATE config and data directories)
export XDG_CONFIG_HOME="$SCRIPT_DIR/nvim-portable/config"
export XDG_DATA_HOME="$SCRIPT_DIR/nvim-portable/local"
export PATH="$SCRIPT_DIR/nvim-portable/nvim-tools/bin:$PATH"

echo ""
echo "Environment:"
echo "  XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
echo "  XDG_DATA_HOME: $XDG_DATA_HOME"
echo "  NVIM config: $XDG_CONFIG_HOME/nvim/"
echo "  NVIM data: $XDG_DATA_HOME/nvim/"
echo ""

# Check directory structure
echo "Directory structure:"
if [[ -d "$XDG_CONFIG_HOME/nvim" ]]; then
    echo "  ✓ Config found: $XDG_CONFIG_HOME/nvim/"
    echo "    Files: $(ls "$XDG_CONFIG_HOME/nvim/" | wc -l) items"
    if [[ -f "$XDG_CONFIG_HOME/nvim/init.lua" ]]; then
        echo "    ✓ init.lua found"
    else
        echo "    ✗ init.lua missing"
    fi
else
    echo "  ✗ Config missing: $XDG_CONFIG_HOME/nvim/"
fi

if [[ -d "$XDG_DATA_HOME/nvim" ]]; then
    echo "  ✓ Data found: $XDG_DATA_HOME/nvim/"
    if [[ -d "$XDG_DATA_HOME/nvim/lazy" ]]; then
        echo "    Plugins: $(ls "$XDG_DATA_HOME/nvim/lazy/" 2>/dev/null | wc -l) plugins"
    else
        echo "    No lazy plugins directory found"
    fi
else
    echo "  ✗ Data missing: $XDG_DATA_HOME/nvim/"
fi

if [[ -d "$SCRIPT_DIR/nvim-portable/nvim-tools/bin" ]]; then
    echo "  ✓ Tools found: $(ls "$SCRIPT_DIR/nvim-portable/nvim-tools/bin/" | wc -l) tools"
else
    echo "  ✗ Tools missing"
fi

echo ""

# Check tools
echo "Checking tools..."
TOOLS=(lua-language-server basedpyright-langserver ruff black shellcheck stylua)
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool not found"
    fi
done

echo ""
echo "Test with:"
echo "  ./nvim-portable.sh test.py"
echo "  ./nvim-portable.sh test.lua"
echo ""
echo "Or manually:"
echo "  export XDG_CONFIG_HOME=$SCRIPT_DIR/nvim-portable/config"
echo "  export XDG_DATA_HOME=$SCRIPT_DIR/nvim-portable/local"
echo "  export PATH=\"$SCRIPT_DIR/nvim-portable/nvim-tools/bin:\$PATH\""
echo "  nvim"
echo ""
echo "Debug Neovim paths:"
echo "  nvim --headless -c 'lua print(\"Config: \" .. vim.fn.stdpath(\"config\"))' -c 'lua print(\"Data: \" .. vim.fn.stdpath(\"data\"))' -c 'quit'"
TESTEOF
    
    chmod +x test-portable.sh
    
    log_info ""
    log_info "🎉 PORTABLE installation complete!"
    log_info ""
    log_info "Created files:"
    log_info "  ./nvim-portable.sh    - Portable launcher"
    log_info "  ./test-portable.sh    - Test script"
    log_info ""
    log_info "Usage:"
    log_info "  ./nvim-portable.sh              # Launch portable Neovim"
    log_info "  ./test-portable.sh              # Test the setup"
    log_info "  ./nvim-portable.sh test.py      # Open file with portable Neovim"
    
else
    # System installation - add to PATH
    log_step "Setting up PATH..."
    SHELL_RC=""
    if [[ -n "$ZSH_VERSION" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi

    if [[ -n "$SHELL_RC" ]] && ! grep -q "nvim-tools" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Neovim tools" >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/share/nvim-tools/bin:$PATH"' >> "$SHELL_RC"
        log_info "✓ Added to $SHELL_RC"
    else
        log_info "PATH already configured or shell not detected"
    fi

    # Set PATH for current session
    export PATH="$HOME/.local/share/nvim-tools/bin:$PATH"

    # Verify installation
    log_step "Verifying installation..."
    TOOLS=(lua-language-server basedpyright-langserver ruff black shellcheck stylua)
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_info "✓ $tool"
        else
            log_warn "✗ $tool not found"
        fi
    done

    log_info ""
    log_info "🎉 SYSTEM installation complete!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Restart your shell or run: source $SHELL_RC"
    log_info "2. Test with: nvim"
    log_info "3. In Neovim, run: :checkhealth"
fi

log_info ""
log_info "Test LSP functionality:"
log_info "  nvim test.py   # Test Python LSP"
log_info "  nvim test.lua  # Test Lua LSP"
log_info "  nvim test.sh   # Test Shell LSP"
EOF

    chmod +x install-on-airgapped.sh
    
    # 5. Create verification script
    cat > verify-setup.sh << 'EOF'
#!/bin/bash

# Verification script for airgapped setup
echo "Verifying Neovim setup..."

# Check Neovim configuration
if [[ -d "$HOME/.config/nvim" ]]; then
    echo "✓ Neovim config found"
else
    echo "✗ Neovim config missing"
fi

# Check tools
if [[ -d "$HOME/.local/share/nvim-tools" ]]; then
    echo "✓ Neovim tools found"
    echo "  Tools available:"
    ls ~/.local/share/nvim-tools/bin/ | sed 's/^/    /'
else
    echo "✗ Neovim tools missing"
fi

# Check plugins
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
    echo "✓ Neovim plugins found"
    echo "  Plugin count: $(ls ~/.local/share/nvim/lazy/ | wc -l)"
else
    echo "✗ Neovim plugins missing"
fi

# Check PATH
if echo "$PATH" | grep -q "nvim-tools"; then
    echo "✓ PATH configured"
else
    echo "✗ PATH not configured (run: source ~/.bashrc)"
fi

echo ""
echo "Test your setup with:"
echo "  nvim --version"
echo "  lua-language-server --version"
echo "  basedpyright-langserver --help"
EOF

    chmod +x verify-setup.sh
    
    # 6. Create README
    cat > README.md << 'EOF'
# Neovim Airgapped Setup Package

This package contains everything needed to run your Neovim setup on an airgapped machine.

## Contents

- `nvim/` - Your Neovim configuration
- `nvim-tools/` - Language servers, formatters, and linters
- `nvim-share/` - Neovim plugins and data
- `install-on-airgapped.sh` - Installation script
- `verify-setup.sh` - Verification script

## Installation Methods

### Method 1: System Installation (Permanent)

Installs to standard user directories (`~/.config/nvim`, `~/.local/share/nvim`):

```bash
./install-on-airgapped.sh
```

### Method 2: Portable Installation (Testing/Temporary)

Installs to current directory for testing without modifying your system:

```bash
./install-on-airgapped.sh portable
```

This creates:
- `nvim-portable.sh` - Portable launcher script
- `test-portable.sh` - Test the portable setup
- `nvim-portable/` - All Neovim files in this directory

## Testing the Portable Installation

After running portable installation:

```bash
# Test the setup
./test-portable.sh

# Use portable Neovim
./nvim-portable.sh

# Open specific files
./nvim-portable.sh test.py
./nvim-portable.sh test.lua
```

## Manual Portable Usage (Advanced)

You can also run portable mode manually with XDG variables:

```bash
# Set environment variables
export XDG_CONFIG_HOME="$(pwd)/nvim-portable"
export XDG_DATA_HOME="$(pwd)/nvim-portable"
export PATH="$(pwd)/nvim-portable/tools/nvim-tools/bin:$PATH"

# Now run Neovim
nvim test.py
```

This is useful for:
- Testing before system installation
- Running multiple Neovim setups
- Completely isolated environments
- CI/CD pipelines

## What Gets Installed

### Neovim Configuration
- `[CONFIG]/nvim/` - Your complete Neovim setup
  - System: `~/.config/nvim/`
  - Portable: `./nvim-portable/nvim/`

### Development Tools
- `[DATA]/nvim-tools/` - All LSPs, formatters, linters
  - lua-language-server (Lua LSP)
  - basedpyright-langserver (Python LSP)  
  - bash-language-server (Shell LSP)
  - yaml-language-server (YAML LSP)
  - ruff (Python linter)
  - black (Python formatter)
  - shellcheck (Shell linter)
  - stylua (Lua formatter)

### Neovim Plugins
- `[DATA]/nvim/` - All your installed plugins and data

Where:
- `[CONFIG]` = `~/.config` (system) or `./nvim-portable` (portable)
- `[DATA]` = `~/.local/share` (system) or `./nvim-portable` (portable)

## Testing Your Setup

### Create Test Files

```bash
# Python test
cat > test.py << 'PYEOF'
def hello_world():
    print("Hello, World!")
    # TODO: Add more functionality

# This line has issues for testing
x=1+2
PYEOF

# Lua test
cat > test.lua << 'LUAEOF'
local function greet(name)
print("Hello, " .. name)
end

-- TODO: Fix formatting
local x=1+2
LUAEOF

# Shell test
cat > test.sh << 'SHEOF'
#!/bin/bash
echo "Hello World"
# TODO: Add error handling
SHEOF
```

### Test LSP Features

In Neovim (system or portable):

1. **Check LSP status**: `:LspInfo`
2. **Hover documentation**: Put cursor on `print` and press `K`
3. **Diagnostics**: Put cursor on issues and press `<leader>d`
4. **Formatting**: Press `<leader>mp`
5. **Linting**: Press `<leader>l`
6. **Health check**: `:checkhealth`

## Portable Mode Benefits

✅ **No system modification** - Test without changing your setup  
✅ **Isolated environment** - Won't conflict with existing Neovim  
✅ **Easy cleanup** - Just delete the directory  
✅ **Multiple setups** - Run different configurations side by side  
✅ **Perfect for testing** - Verify everything works before system install  

## Troubleshooting

### Tools not found
```bash
# Check PATH
echo $PATH | grep nvim-tools

# Add manually (portable)
export PATH="$(pwd)/nvim-portable/tools/nvim-tools/bin:$PATH"

# Add manually (system)
export PATH="$HOME/.local/share/nvim-tools/bin:$PATH"
```

### Portable mode not working
```bash
# Check XDG variables
echo $XDG_CONFIG_HOME
echo $XDG_DATA_HOME

# Set manually
export XDG_CONFIG_HOME="$(pwd)/nvim-portable"
export XDG_DATA_HOME="$(pwd)/nvim-portable"
```

### LSP not starting
```bash
# Check tool availability
which lua-language-server
which basedpyright-langserver

# Check Neovim config location
nvim --version | grep "config"
nvim --version | grep "data"
```

## Package Information

- **Created**: $(date)
- **From**: $(hostname)
- **User**: $(whoami)
- **Package size**: Will be shown after creation

## Migration Path

1. **Test first**: Use portable mode to verify everything works
2. **System install**: Once confirmed, run system installation
3. **Cleanup**: Remove portable directory after system install successful
EOF

    cd "$current_dir"
    
    # Create archive
    log_step "Creating archive..."
    tar -czf "${package_dir}.tar.gz" "$package_dir"
    
    log_info ""
    log_info "🎉 Transfer package created!"
    log_info "📦 Archive: ${package_dir}.tar.gz"
    log_info "📁 Directory: $package_dir/"
    log_info ""
    log_info "To transfer to airgapped machine:"
    log_info "1. Copy ${package_dir}.tar.gz to target machine"
    log_info "2. Extract: tar -xzf ${package_dir}.tar.gz"
    log_info "3. Run: cd $package_dir && ./install-on-airgapped.sh"
    
    # Show size
    local size=$(du -h "${package_dir}.tar.gz" | cut -f1)
    log_info ""
    log_info "Package size: $size"
}

# Function to show what directories are needed
show_required_directories() {
    log_step "Required directories for airgapped machine:"
    echo ""
    echo "📁 Complete directory structure needed:"
    echo ""
    echo "~/.config/nvim/                    # Your Neovim configuration"
    echo "├── init.lua                       # Main config file"  
    echo "├── lua/gov/                       # Your config modules"
    echo "└── ..."
    echo ""
    echo "~/.local/share/nvim-tools/         # Development tools"
    echo "├── bin/                           # Tool executables"
    echo "├── npm/                           # npm packages"
    echo "└── ..."
    echo ""
    echo "~/.local/share/nvim/               # Neovim data and plugins"
    echo "├── lazy/                          # Lazy.nvim plugins"
    echo "├── state.json                     # Neovim state"
    echo "└── ..."
    echo ""
    echo "~/.bashrc (or ~/.zshrc)            # Shell configuration"
    echo "# Must contain: export PATH=\"\$HOME/.local/share/nvim-tools/bin:\$PATH\""
    echo ""
}

# Main menu
case "${1:-}" in
    "package")
        create_transfer_package
        ;;
    "show")
        show_required_directories
        ;;
    *)
        echo "Airgapped Machine Transfer Helper"
        echo ""
        echo "Usage:"
        echo "  $0 package    # Create complete transfer package"
        echo "  $0 show       # Show required directories"
        echo ""
        echo "The 'package' command creates everything needed for airgapped deployment."
        ;;
esac
