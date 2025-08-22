#!/bin/bash

# Update Neovim Tools Script
# This script updates all your development tools to the latest versions
# Run this every few months to get fresh binaries

set -e

# Configuration
INSTALL_DIR="$HOME/.local/share/nvim-tools"
BIN_DIR="$INSTALL_DIR/bin"
NPM_DIR="$INSTALL_DIR/npm"
BACKUP_DIR="$HOME/.local/share/nvim-tools-backup-$(date +%Y%m%d-%H%M%S)"
DEBUG_MODE=${DEBUG_MODE:-false}

# Tool configurations - easily add/remove tools here
declare -A NPM_TOOLS=(
    ["basedpyright"]="basedpyright-langserver"
    ["basedpyright"]="basedpyright"
    ["bash-language-server"]="bash-language-server"
    ["ansible-language-server"]=""
    ["yaml-language-server"]="yaml-language-server"
    ["vscode-langservers-extracted"]="vscode-json-language-server"
    ["@microsoft/compose-language-service"]="docker-compose-langserver"
)

declare -a PYTHON_TOOLS=(
    "ruff"
    "black"
    # Add more Python tools here
    # "mypy"
    # "flake8"
)

declare -A GO_TOOLS=(
    ["shfmt"]="mvdan.cc/sh/v3/cmd/shfmt@latest"
    # Add more Go tools here
    # ["goimports"]="golang.org/x/tools/cmd/goimports@latest"
    # ["golangci-lint"]="github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
)

declare -A BINARY_TOOLS=(
    ["lua-language-server"]="LuaLS/lua-language-server"
    ["shellcheck"]="koalaman/shellcheck"
    ["stylua"]="JohnnyMorganz/StyLua"
    # Add more binary tools here
    # ["hadolint"]="hadolint/hadolint"
    # ["actionlint"]="rhysd/actionlint"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

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
    
    for tool in "${!NPM_TOOLS[@]}"; do
        local symlink_name="${NPM_TOOLS[$tool]}"
        log_info "Updating $tool..."
        NPM_CONFIG_PREFIX="$NPM_DIR" npm install -g "$tool@latest" || log_warn "Failed to update $tool"
        
        # Create symlink if specified
        if [[ -n "$symlink_name" ]]; then
            # Make sure the target exists before creating symlink
            if [[ -f "$NPM_DIR/bin/$symlink_name" ]]; then
                # Use relative path for symlink to avoid hardcoded paths
                # Change to BIN_DIR to ensure relative path works correctly
                (cd "$BIN_DIR" && ln -sf "../npm/bin/$symlink_name" "$symlink_name") 2>/dev/null || log_warn "Failed to create symlink for $symlink_name"
                log_debug "Created symlink: $BIN_DIR/$symlink_name -> ../npm/bin/$symlink_name"
            else
                log_warn "Target $NPM_DIR/bin/$symlink_name does not exist, skipping symlink creation"
            fi
        fi
    done
}

# Function to install/update Python tools
update_python_tools() {
    if ! command_exists pip; then
        log_warn "pip not found. Skipping Python tools."
        return 0
    fi
    
    log_step "Updating Python tools..."
    
    for tool in "${PYTHON_TOOLS[@]}"; do
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
    
    # Check Go version
    local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | head -1)
    log_info "Go version: $go_version"
    
    for tool_name in "${!GO_TOOLS[@]}"; do
        local go_pkg="${GO_TOOLS[$tool_name]}"
        log_info "Installing $tool_name from $go_pkg..."
        
        # Try to install with detailed error reporting
        if GOBIN="$BIN_DIR" go install "$go_pkg" 2>&1; then
            log_info "✓ Successfully installed $tool_name"
            
            # Verify the binary exists
            if [[ -f "$BIN_DIR/$tool_name" ]]; then
                log_info "✓ Binary confirmed at $BIN_DIR/$tool_name"
            else
                log_warn "✗ Binary not found at expected location $BIN_DIR/$tool_name"
                
                # Check if it ended up in default GOPATH/bin
                local gopath_bin="${GOPATH:-$HOME/go}/bin"
                if [[ -f "$gopath_bin/$tool_name" ]]; then
                    log_info "Found $tool_name in $gopath_bin, creating relative symlink..."
                    # Create relative symlink by changing to BIN_DIR first
                    local rel_gopath=$(realpath --relative-to="$BIN_DIR" "$gopath_bin" 2>/dev/null || echo "$gopath_bin")
                    (cd "$BIN_DIR" && ln -sf "$rel_gopath/$tool_name" "$tool_name")
                else
                    log_warn "Could not locate $tool_name binary anywhere"
                fi
            fi
        else
            log_error "Failed to install $tool_name"
            log_info "Trying alternative installation method..."
            
            # Fallback: try without GOBIN, then symlink
            if go install "$go_pkg" 2>&1; then
                local gopath_bin="${GOPATH:-$HOME/go}/bin"
                if [[ -f "$gopath_bin/$tool_name" ]]; then
                    log_info "Installed to $gopath_bin, creating relative symlink..."
                    # Create relative symlink by changing to BIN_DIR first
                    local rel_gopath=$(realpath --relative-to="$BIN_DIR" "$gopath_bin" 2>/dev/null || echo "$gopath_bin")
                    (cd "$BIN_DIR" && ln -sf "$rel_gopath/$tool_name" "$tool_name")
                else
                    log_warn "Failed to install $tool_name with fallback method"
                fi
            else
                log_warn "All installation methods failed for $tool_name"
            fi
        fi
    done
}

# Function to get binary pattern for different tools
get_binary_pattern() {
    local tool="$1"
    local repo="$2"
    
    case "$tool" in
        "lua-language-server")
            echo "$SYSTEM_OS-$SYSTEM_ARCH.tar.gz"
            ;;
        "shellcheck")
            local shellcheck_arch="$SYSTEM_ARCH"
            case "$SYSTEM_ARCH" in
                x64) shellcheck_arch="x86_64" ;;
                arm64) shellcheck_arch="aarch64" ;;
            esac
            echo "$SYSTEM_OS.$shellcheck_arch.tar.xz"
            ;;
        "stylua")
            if [[ "$SYSTEM_OS" == "linux" ]]; then
                echo "linux.zip"
            elif [[ "$SYSTEM_OS" == "darwin" ]]; then
                echo "macos.zip"
            fi
            ;;
        "hadolint")
            if [[ "$SYSTEM_OS" == "linux" ]]; then
                echo "Linux-$SYSTEM_ARCH"
            elif [[ "$SYSTEM_OS" == "darwin" ]]; then
                echo "Darwin-$SYSTEM_ARCH"
            fi
            ;;
        "actionlint")
            if [[ "$SYSTEM_OS" == "linux" ]]; then
                echo "linux_amd64.tar.gz"
            elif [[ "$SYSTEM_OS" == "darwin" ]]; then
                echo "darwin_amd64.tar.gz"
            fi
            ;;
        *)
            # Default pattern - you can customize this
            echo "$SYSTEM_OS-$SYSTEM_ARCH"
            ;;
    esac
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
        local binary_name="${3:-$name}"
        
        log_info "Updating $name..."
        cd "$temp_dir"
        
        # Get the appropriate pattern for this tool
        local pattern=$(get_binary_pattern "$name" "$repo")
        if [[ -z "$pattern" ]]; then
            log_warn "No pattern defined for $name on $SYSTEM_OS-$SYSTEM_ARCH, skipping..."
            return 1
        fi
        
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
    for tool_name in "${!BINARY_TOOLS[@]}"; do
        local repo="${BINARY_TOOLS[$tool_name]}"
        install_binary "$tool_name" "$repo" "$tool_name"
    done
    
    rm -rf "$temp_dir"
}

# Function to verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    # Collect all tools that should be available
    local tools=()
    
    # Add npm tools that have symlinks
    for tool in "${!NPM_TOOLS[@]}"; do
        local symlink_name="${NPM_TOOLS[$tool]}"
        if [[ -n "$symlink_name" ]]; then
            tools+=("$symlink_name")
        fi
    done
    
    # Add Python tools
    tools+=("${PYTHON_TOOLS[@]}")
    
    # Add Go tools
    for tool in "${!GO_TOOLS[@]}"; do
        tools+=("$tool")
    done
    
    # Add binary tools
    for tool in "${!BINARY_TOOLS[@]}"; do
        tools+=("$tool")
    done
    
    local failed_tools=()
    local success_count=0
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_info "✓ $tool"
            ((success_count++))
        else
            log_warn "✗ $tool not found"
            failed_tools+=("$tool")
        fi
    done
    
    local total_tools=${#tools[@]}
    log_info "Verification complete: $success_count/$total_tools tools working"
    
    if [[ ${#failed_tools[@]} -eq 0 ]]; then
        log_info "✓ All tools verified successfully!"
        return 0
    elif [[ $success_count -gt $((total_tools / 2)) ]]; then
        log_warn "Most tools are working. Failed tools: ${failed_tools[*]}"
        log_info "You can continue using the working tools or re-run the script to try fixing the failed ones."
        return 0  # Don't fail if more than half the tools work
    else
        log_error "Too many tools failed. Failed tools: ${failed_tools[*]}"
        return 1
    fi
}

# Function to test tools
test_tools() {
    log_step "Testing tools..."
    
    # Test each tool briefly
    lua-language-server --version >/dev/null 2>&1 && log_info "✓ lua-language-server working" || log_warn "✗ lua-language-server test failed"
    
    if command_exists basedpyright-langserver; then
        echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}' | timeout 5 basedpyright-langserver --stdio >/dev/null 2>&1 && log_info "✓ basedpyright-langserver working" || log_warn "✗ basedpyright-langserver test failed"
    fi
    
    ruff --version >/dev/null 2>&1 && log_info "✓ ruff working" || log_warn "✗ ruff test failed"
    black --version >/dev/null 2>&1 && log_info "✓ black working" || log_warn "✗ black test failed"
    shellcheck --version >/dev/null 2>&1 && log_info "✓ shellcheck working" || log_warn "✗ shellcheck test failed"
    stylua --version >/dev/null 2>&1 && log_info "✓ stylua working" || log_warn "✗ stylua test failed"
    
    if command_exists shfmt; then
        shfmt --version >/dev/null 2>&1 && log_info "✓ shfmt working" || log_warn "✗ shfmt test failed"
    fi
}

# Function to show help
show_help() {
    cat << 'EOF'
Neovim Tools Update Script

USAGE:
    ./update_nvim_tools.sh [OPTIONS]

OPTIONS:
    -h, --help       Show this help message
    --debug          Enable debug output
    --list           List all configured tools
    --verify-only    Only verify existing installation without updating
    --test-only      Only test existing tools without updating

CUSTOMIZATION:
To add/remove tools, edit the tool arrays at the top of this script:

    NPM_TOOLS        - Node.js packages
    PYTHON_TOOLS     - Python packages  
    GO_TOOLS         - Go packages
    BINARY_TOOLS     - Binary releases from GitHub

Examples:
    ./update_nvim_tools.sh                    # Full update
    ./update_nvim_tools.sh --list             # Show configured tools
    ./update_nvim_tools.sh --verify-only      # Check if tools are installed
    ./update_nvim_tools.sh --test-only        # Test if tools work

EOF
}

# Function to list configured tools
list_tools() {
    echo "Configured Tools:"
    echo
    
    echo "Node.js Tools (NPM_TOOLS):"
    for tool in "${!NPM_TOOLS[@]}"; do
        local symlink="${NPM_TOOLS[$tool]}"
        if [[ -n "$symlink" ]]; then
            echo "  $tool -> $symlink"
        else
            echo "  $tool"
        fi
    done
    echo
    
    echo "Python Tools (PYTHON_TOOLS):"
    for tool in "${PYTHON_TOOLS[@]}"; do
        echo "  $tool"
    done
    echo
    
    echo "Go Tools (GO_TOOLS):"
    for tool in "${!GO_TOOLS[@]}"; do
        echo "  $tool (${GO_TOOLS[$tool]})"
    done
    echo
    
    echo "Binary Tools (BINARY_TOOLS):"
    for tool in "${!BINARY_TOOLS[@]}"; do
        echo "  $tool (${BINARY_TOOLS[$tool]})"
    done
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                DEBUG_MODE=true
                log_debug "Debug mode enabled"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --list)
                list_tools
                exit 0
                ;;
            --verify-only)
                detect_system
                verify_installation
                exit $?
                ;;
            --test-only)
                detect_system
                test_tools
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
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
    mkdir -p "$NPM_DIR"
    
    # Detect system
    detect_system
    
    # Backup current installation
    backup_current_installation
    
    # Update tools (continue even if some fail)
    local npm_success=true
    local python_success=true
    local go_success=true
    local binary_success=true
    
    update_npm_tools || npm_success=false
    update_python_tools || python_success=false
    update_go_tools || go_success=false
    update_binary_releases || binary_success=false
    
    # Report results
    if [[ "$npm_success" == "true" && "$python_success" == "true" && "$go_success" == "true" && "$binary_success" == "true" ]]; then
        log_info "✓ All updates completed successfully"
    else
        log_warn "Some updates had issues:"
        [[ "$npm_success" == "false" ]] && log_warn "  - NPM tools had issues"
        [[ "$python_success" == "false" ]] && log_warn "  - Python tools had issues"  
        [[ "$go_success" == "false" ]] && log_warn "  - Go tools had issues"
        [[ "$binary_success" == "false" ]] && log_warn "  - Binary tools had issues"
        log_info "Continuing with verification..."
    fi
    
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
}

# Trap to restore backup on failure
trap 'log_error "Update failed"; restore_backup' ERR

# Run main function
main "$@"
