#!/bin/bash

# Update Neovim Tools Script
# This script updates all your development tools to the latest versions
# Run this every few months to get fresh binaries

set -e

# Configuration
INSTALL_DIR="$HOME/.local/share/nvim-tools"
BIN_DIR="$INSTALL_DIR/bin"
BACKUP_DIR="$HOME/.local/share/nvim-tools-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup current installation
backup_current_installation() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log_step "Backing up current installation to $BACKUP_DIR"
        cp -r "$INSTALL_DIR" "$BACKUP_DIR"
        log_info "✓ Backup created at $BACKUP_DIR"
    else
        log_warn "No existing installation found to backup"
    fi
}

# Function to restore from backup
restore_backup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        log_warn "Restoring from backup due to failure..."
        rm -rf "$INSTALL_DIR"
        mv "$BACKUP_DIR" "$INSTALL_DIR"
        log_info "✓ Restored from backup"
    fi
}

# Function to detect system
detect_system() {
    export SYSTEM_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    export SYSTEM_ARCH=$(uname -m)
    
    case "$SYSTEM_ARCH" in
        x86_64) export SYSTEM_ARCH="x64" ;;
        aarch64|arm64) export SYSTEM_ARCH="arm64" ;;
    esac
    
    log_info "Detected system: $SYSTEM_OS-$SYSTEM_ARCH"
}

# Function to get latest GitHub release URL
get_latest_release_url() {
    local repo="$1"
    local pattern="$2"
    
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local download_url=$(curl -s "$api_url" | grep -o "https://github.com/$repo/releases/download/[^\"]*$pattern[^\"]*" | head -1)
    
    if [[ -n "$download_url" ]]; then
        echo "$download_url"
        return 0
    else
        return 1
    fi
}

# Function to install/update npm tools
update_npm_tools() {
    if ! command_exists npm; then
        log_warn "npm not found. Skipping Node.js tools."
        return 0
    fi
    
    log_step "Updating Node.js tools..."
    
    local npm_tools=(
        "basedpyright"
        "bash-language-server" 
        "ansible-language-server"
        "yaml-language-server"
        "vscode-langservers-extracted"
        "@microsoft/compose-language-service"
    )
    
    for tool in "${npm_tools[@]}"; do
        log_info "Updating $tool..."
        NPM_CONFIG_PREFIX="$INSTALL_DIR/npm" npm install -g "$tool@latest" || log_warn "Failed to update $tool"
    done
    
    # Create/update symlinks
    ln -sf "$INSTALL_DIR/npm/bin/basedpyright-langserver" "$BIN_DIR/basedpyright-langserver" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/npm/bin/bash-language-server" "$BIN_DIR/bash-language-server" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/npm/bin/yaml-language-server" "$BIN_DIR/yaml-language-server" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/npm/bin/vscode-json-language-server" "$BIN_DIR/vscode-json-language-server" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/npm/bin/docker-compose-langserver" "$BIN_DIR/docker-compose-langserver" 2>/dev/null || true
}

# Function to install/update Python tools
update_python_tools() {
    if ! command_exists pip; then
        log_warn "pip not found. Skipping Python tools."
        return 0
    fi
    
    log_step "Updating Python tools..."
    
    local python_tools=("ruff" "black")
    
    for tool in "${python_tools[@]}"; do
        log_info "Updating $tool..."
        pip install --user --upgrade "$tool" || log_warn "Failed to update $tool"
    done
}

# Function to install/update Go tools
update_go_tools() {
    if ! command_exists go; then
        log_warn "go not found. Skipping Go tools."
        return 0
    fi
    
    log_step "Updating Go tools..."
    
    log_info "Updating shfmt..."
    GOBIN="$BIN_DIR" go install mvdan.cc/sh/v3/cmd/shfmt@latest || log_warn "Failed to update shfmt"
}

# Function to install/update binary releases
update_binary_releases() {
    log_step "Updating binary releases..."
    
    local temp_dir="/tmp/nvim-tools-update-$(date +%s)"
    mkdir -p "$temp_dir"
    
    # Function to download and install a binary
    install_binary() {
        local name="$1"
        local repo="$2"
        local pattern="$3"
        local binary_name="${4:-$name}"
        
        log_info "Updating $name..."
        cd "$temp_dir"
        
        # Try to get latest release
        local url
        if url=$(get_latest_release_url "$repo" "$pattern"); then
            log_info "Found latest release: $url"
        else
            log_warn "Could not find latest release for $name, skipping..."
            return 1
        fi
        
        # Download and extract
        if curl -L -f "$url" -o "${name}_download"; then
            local file_type=$(file "${name}_download" 2>/dev/null || echo "unknown")
            
            if [[ "$file_type" == *"gzip compressed"* ]]; then
                tar -xzf "${name}_download" || return 1
            elif [[ "$file_type" == *"XZ compressed"* ]]; then
                tar -xJf "${name}_download" || return 1
            elif [[ "$file_type" == *"Zip archive"* ]]; then
                unzip -q "${name}_download" || return 1
            else
                # Direct binary
                cp "${name}_download" "$BIN_DIR/$name"
                chmod +x "$BIN_DIR/$name"
                rm -f "${name}_download"
                return 0
            fi
            
            # Find and install the binary
            if [[ "$name" == "lua-language-server" ]]; then
                # Special handling for lua-language-server
                rm -rf "$INSTALL_DIR/lua-language-server"
                mkdir -p "$INSTALL_DIR/lua-language-server"
                cp -r * "$INSTALL_DIR/lua-language-server/"
                
                cat > "$BIN_DIR/lua-language-server" << EOF
#!/bin/bash
cd "$INSTALL_DIR/lua-language-server"
exec ./bin/lua-language-server "\$@"
EOF
                chmod +x "$BIN_DIR/lua-language-server"
            else
                # Regular binary installation
                local found_binary=$(find . -name "$binary_name" -type f -executable | head -1)
                if [[ -n "$found_binary" ]]; then
                    cp "$found_binary" "$BIN_DIR/$name"
                    chmod +x "$BIN_DIR/$name"
                else
                    log_warn "Binary '$binary_name' not found in $name archive"
                    return 1
                fi
            fi
            
            # Cleanup
            rm -rf ./*
            log_info "✓ $name updated successfully"
        else
            log_warn "Failed to download $name"
            return 1
        fi
    }
    
    # Update each binary tool
    if [[ "$SYSTEM_OS" == "linux" ]]; then
        install_binary "lua-language-server" "LuaLS/lua-language-server" "$SYSTEM_OS-$SYSTEM_ARCH.tar.gz" "lua-language-server"
        
        # Adjust arch for shellcheck
        local shellcheck_arch="$SYSTEM_ARCH"
        case "$SYSTEM_ARCH" in
            x64) shellcheck_arch="x86_64" ;;
            arm64) shellcheck_arch="aarch64" ;;
        esac
        install_binary "shellcheck" "koalaman/shellcheck" "$SYSTEM_OS.$shellcheck_arch.tar.xz" "shellcheck"
        
        install_binary "stylua" "JohnnyMorganz/StyLua" "linux.zip" "stylua"
    elif [[ "$SYSTEM_OS" == "darwin" ]]; then
        install_binary "lua-language-server" "LuaLS/lua-language-server" "$SYSTEM_OS-$SYSTEM_ARCH.tar.gz" "lua-language-server"
        install_binary "shellcheck" "koalaman/shellcheck" "$SYSTEM_OS.x86_64.tar.xz" "shellcheck"
        install_binary "stylua" "JohnnyMorganz/StyLua" "macos.zip" "stylua"
    fi
    
    rm -rf "$temp_dir"
}

# Function to verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    local tools=(
        "lua-language-server"
        "basedpyright-langserver" 
        "bash-language-server"
        "yaml-language-server"
        "ruff"
        "black"
        "shellcheck"
        "stylua"
    )
    
    local failed_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_info "✓ $tool"
        else
            log_warn "✗ $tool not found"
            failed_tools+=("$tool")
        fi
    done
    
    if [[ ${#failed_tools[@]} -eq 0 ]]; then
        log_info "✓ All tools verified successfully!"
        return 0
    else
        log_error "Failed tools: ${failed_tools[*]}"
        return 1
    fi
}

# Function to test tools
test_tools() {
    log_step "Testing tools..."
    
    # Test each tool briefly
    lua-language-server --version >/dev/null 2>&1 && log_info "✓ lua-language-server working" || log_warn "✗ lua-language-server test failed"
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}' | timeout 5 basedpyright-langserver --stdio >/dev/null 2>&1 && log_info "✓ basedpyright-langserver working" || log_warn "✗ basedpyright-langserver test failed"
    ruff --version >/dev/null 2>&1 && log_info "✓ ruff working" || log_warn "✗ ruff test failed"
    black --version >/dev/null 2>&1 && log_info "✓ black working" || log_warn "✗ black test failed"
    shellcheck --version >/dev/null 2>&1 && log_info "✓ shellcheck working" || log_warn "✗ shellcheck test failed"
    stylua --version >/dev/null 2>&1 && log_info "✓ stylua working" || log_warn "✗ stylua test failed"
}

# Main execution
main() {
    log_info "Starting Neovim tools update..."
    log_info "This will update all your development tools to the latest versions"
    
    # Confirm before proceeding
    read -p "Continue with update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi
    
    # Create directories
    mkdir -p "$BIN_DIR"
    mkdir -p "$INSTALL_DIR/npm"
    
    # Detect system
    detect_system
    
    # Backup current installation
    backup_current_installation
    
    # Update tools
    if update_npm_tools && update_python_tools && update_go_tools && update_binary_releases; then
        log_info "✓ All updates completed successfully"
        
        # Verify and test
        if verify_installation; then
            test_tools
            log_info ""
            log_info "🎉 Update completed successfully!"
            log_info "Tools installed to: $INSTALL_DIR"
            log_info "Backup saved to: $BACKUP_DIR"
            log_info ""
            log_info "You can now test your setup with:"
            log_info "  nvim test.py  # Test Python LSP"
            log_info "  nvim test.lua # Test Lua LSP"
            log_info "  nvim test.sh  # Test Shell LSP"
            
            # Clean up old backup if everything works
            if [[ -d "$BACKUP_DIR" ]]; then
                read -p "Remove backup directory? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$BACKUP_DIR"
                    log_info "Backup removed"
                fi
            fi
        else
            log_error "Verification failed"
            restore_backup
            exit 1
        fi
    else
        log_error "Update failed"
        restore_backup
        exit 1
    fi
}

# Trap to restore backup on failure
trap 'log_error "Update failed"; restore_backup' ERR

# Run main function
main "$@"
