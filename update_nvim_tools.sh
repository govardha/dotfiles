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
# Note: The 'basedpyright' tool is listed twice in the original script.
# This has been corrected to a single entry.
declare -A NPM_TOOLS=(
    ["basedpyright"]="basedpyright-langserver"
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
        cp -r "$INSTALL_DIR" "$BACKUP_DIR" || { log_error "Failed to create backup"; return 1; }
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
    # Fallback to tags if no releases are found (e.g. for actionlint)
    local fallback_api_url="https://api.github.com/repos/$repo/tags"
    local download_url
    
    # Try releases first
    download_url=$(curl -s "$api_url" | grep -o "https://github.com/$repo/releases/download/[^\"]*$pattern[^\"]*" | head -1)
    
    # If not found, try tags (e.g. for actionlint)
    if [[ -z "$download_url" ]]; then
        log_debug "No release found, trying tags..."
        local latest_tag=$(curl -s "$fallback_api_url" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        if [[ -n "$latest_tag" ]]; then
            download_url="https://github.com/$repo/releases/download/$latest_tag/$pattern"
            log_debug "Found tag: $latest_tag, generated URL: $download_url"
        fi
    fi
    
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
        if NPM_CONFIG_PREFIX="$NPM_DIR" npm install -g "$tool@latest"; then
            log_info "✓ Successfully installed $tool"
            
            # Create symlink if specified
            if [[ -n "$symlink_name" ]]; then
                if [[ -f "$NPM_DIR/bin/$symlink_name" ]]; then
                    (cd "$BIN_DIR" && ln -sf "../npm/bin/$symlink_name" "$symlink_name") || log_warn "Failed to create symlink for $symlink_name"
                    log_debug "Created symlink: $BIN_DIR/$symlink_name -> ../npm/bin/$symlink_name"
                else
                    log_warn "Target $NPM_DIR/bin/$symlink_name does not exist, skipping symlink creation"
                fi
            fi
        else
            log_error "Failed to update $tool"
            return 1
        fi
    done
}

# Function to install/update Python tools
# Function to install/update Python tools
update_python_tools() {
    if ! command_exists pip; then
        log_warn "pip not found. Skipping Python tools."
        return 0
    fi

    log_step "Updating Python tools..."

    # Create a virtual environment specifically for the Python tools if it doesn't exist
    local venv_dir="$INSTALL_DIR/py-venv"
    if [[ ! -d "$venv_dir" ]]; then
        log_info "Creating virtual environment at $venv_dir..."
        python3 -m venv "$venv_dir" || { log_error "Failed to create Python virtual environment"; return 1; }
    fi

    # Activate the virtual environment
    source "$venv_dir/bin/activate"

    # Now install/upgrade tools within the virtual environment
    for tool in "${PYTHON_TOOLS[@]}"; do
        log_info "Updating $tool..."
        pip install --upgrade "$tool" || { log_error "Failed to update $tool"; return 1; }
        log_info "✓ Successfully updated $tool"

        # Create a symlink to the binary in the main bin directory
        local venv_bin="$venv_dir/bin"
        if [[ -f "$venv_bin/$tool" ]]; then
            (cd "$BIN_DIR" && ln -sf "$(realpath --relative-to="$BIN_DIR" "$venv_bin/$tool")" "$tool") 2>/dev/null || log_warn "Failed to create symlink for $tool"
        fi
    done

    # Deactivate the virtual environment
    deactivate

    return 0
}
# Function to install/update Go tools
update_go_tools() {
    if ! command_exists go; then
        log_warn "go not found. Skipping Go tools."
        return 0
    fi
    
    log_step "Updating Go tools..."
    
    local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | head -1)
    log_info "Go version: $go_version"
    
    for tool_name in "${!GO_TOOLS[@]}"; do
        local go_pkg="${GO_TOOLS[$tool_name]}"
        log_info "Installing $tool_name from $go_pkg..."
        
        # Use GOBIN to ensure installation to the correct directory
        if GOBIN="$BIN_DIR" go install "$go_pkg" 2>&1; then
            if [[ -f "$BIN_DIR/$tool_name" ]]; then
                log_info "✓ Successfully installed $tool_name to $BIN_DIR"
            else
                log_warn "✗ Binary not found at expected location $BIN_DIR/$tool_name"
                return 1 # Fail fast if the binary isn't where it should be
            fi
        else
            log_error "Failed to install $tool_name"
            return 1
        fi
    done
}

# Function to get binary pattern for different tools
get_binary_pattern() {
    local tool="$1"
    local os="$SYSTEM_OS"
    local arch="$SYSTEM_ARCH"
    
    case "$tool" in
        "lua-language-server")
            echo "lua-language-server-$os-$arch.tar.gz"
            ;;
        "shellcheck")
            local shellcheck_arch="$arch"
            case "$arch" in
                x64) shellcheck_arch="x86_64" ;;
                arm64) shellcheck_arch="aarch64" ;;
            esac
            echo "shellcheck-v[0-9.]*.$os.$shellcheck_arch.tar.xz"
            ;;
        "stylua")
            case "$os" in
                linux) echo "stylua-$arch-unknown-linux-gnu.zip" ;;
                darwin) echo "stylua-$arch-apple-darwin.zip" ;;
                *) echo "" ;;
            esac
            ;;
        "hadolint")
            case "$os" in
                linux) echo "hadolint-Linux-$arch" ;;
                darwin) echo "hadolint-Darwin-$arch" ;;
                *) echo "" ;;
            esac
            ;;
        "actionlint")
            case "$os" in
                linux) echo "actionlint_linux_$arch.tar.gz" ;;
                darwin) echo "actionlint_darwin_$arch.tar.gz" ;;
                *) echo "" ;;
            esac
            ;;
        *)
            # Default pattern
            echo "$os-$arch"
            ;;
    esac
}

# Function to install/update binary releases
update_binary_releases() {
    log_step "Updating binary releases..."
    
    local temp_dir="/tmp/nvim-tools-update-$(date +%s)"
    mkdir -p "$temp_dir" || { log_error "Failed to create temp directory"; return 1; }
    
    # Function to download and install a binary
    install_binary() {
        local name="$1"
        local repo="$2"
        
        log_info "Updating $name..."
        cd "$temp_dir"
        
        local pattern=$(get_binary_pattern "$name")
        if [[ -z "$pattern" ]]; then
            log_warn "No pattern defined for $name on $SYSTEM_OS-$SYSTEM_ARCH, skipping..."
            return 0
        fi
        
        local url
        if ! url=$(get_latest_release_url "$repo" "$pattern"); then
            log_warn "Could not find latest release for $name, skipping..."
            return 0
        fi
        
        log_info "Found latest release: $url"
        
        local filename="${url##*/}"
        if ! curl -L -f "$url" -o "$filename"; then
            log_warn "Failed to download $name from $url"
            return 1
        fi
        
        local binary_path=""
        local extract_dir="$temp_dir/extract"
        mkdir -p "$extract_dir"
        
        if [[ "$filename" == *".tar.gz" ]]; then
            tar -xzf "$filename" -C "$extract_dir" || return 1
        elif [[ "$filename" == *".tar.xz" ]]; then
            tar -xJf "$filename" -C "$extract_dir" || return 1
        elif [[ "$filename" == *".zip" ]]; then
            unzip -q "$filename" -d "$extract_dir" || return 1
        else
            # Direct binary file
            binary_path="$temp_dir/$filename"
            mv "$filename" "$binary_path"
        fi
        
        if [[ -z "$binary_path" ]]; then
            # Find the binary in the extracted directory
            if [[ "$name" == "lua-language-server" ]]; then
                # Special handling for lua-language-server
                rm -rf "$INSTALL_DIR/lua-language-server"
                cp -r "$extract_dir" "$INSTALL_DIR/lua-language-server"
                
                cat > "$BIN_DIR/lua-language-server" << EOF
#!/bin/bash
cd "$INSTALL_DIR/lua-language-server"
exec ./bin/lua-language-server "\$@"
EOF
                chmod +x "$BIN_DIR/lua-language-server"
            else
                local found_binary=$(find "$extract_dir" -name "$name*" -type f -executable | head -1)
                if [[ -n "$found_binary" ]]; then
                    binary_path="$found_binary"
                else
                    log_warn "Binary '$name' not found in archive"
                    return 1
                fi
                cp "$binary_path" "$BIN_DIR/$name"
                chmod +x "$BIN_DIR/$name"
            fi
        fi
        
        log_info "✓ $name updated successfully"
        rm -rf "$extract_dir" "$filename"
    }
    
    local success=true
    for tool_name in "${!BINARY_TOOLS[@]}"; do
        local repo="${BINARY_TOOLS[$tool_name]}"
        install_binary "$tool_name" "$repo" || success=false
    done
    
    rm -rf "$temp_dir"
    $success
}

# Function to verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    local tools=()
    for tool in "${!NPM_TOOLS[@]}"; do
        local symlink_name="${NPM_TOOLS[$tool]}"
        if [[ -n "$symlink_name" ]]; then
            tools+=("$symlink_name")
        fi
    done
    
    tools+=("${PYTHON_TOOLS[@]}")
    for tool in "${!GO_TOOLS[@]}"; do
        tools+=("$tool")
    done
    
    for tool in "${!BINARY_TOOLS[@]}"; do
        tools+=("$tool")
    done
    
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
        log_error "The following tools failed verification: ${failed_tools[*]}"
        return 1
    fi
}

# Function to test tools
test_tools() {
    log_step "Testing tools..."
    
    local test_passed=true
    
    command_exists lua-language-server && lua-language-server --version >/dev/null 2>&1 && log_info "✓ lua-language-server working" || { log_warn "✗ lua-language-server test failed"; test_passed=false; }
    
    if command_exists basedpyright-langserver; then
        echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}' | timeout 5 basedpyright-langserver --stdio >/dev/null 2>&1 && log_info "✓ basedpyright-langserver working" || { log_warn "✗ basedpyright-langserver test failed"; test_passed=false; }
    fi
    
    command_exists ruff && ruff --version >/dev/null 2>&1 && log_info "✓ ruff working" || { log_warn "✗ ruff test failed"; test_passed=false; }
    command_exists black && black --version >/dev/null 2>&1 && log_info "✓ black working" || { log_warn "✗ black test failed"; test_passed=false; }
    command_exists shellcheck && shellcheck --version >/dev/null 2>&1 && log_info "✓ shellcheck working" || { log_warn "✗ shellcheck test failed"; test_passed=false; }
    command_exists stylua && stylua --version >/dev/null 2>&1 && log_info "✓ stylua working" || { log_warn "✗ stylua test failed"; test_passed=false; }
    command_exists shfmt && shfmt --version >/dev/null 2>&1 && log_info "✓ shfmt working" || { log_warn "✗ shfmt test failed"; test_passed=false; }
    
    if $test_passed; then
        log_info "✓ All configured tools passed basic tests."
    else
        log_warn "Some tools failed basic tests."
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
    
    read -p "Continue with update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi
    
    mkdir -p "$BIN_DIR" "$NPM_DIR"
    
    detect_system
    
    backup_current_installation
    
    log_step "Starting tool updates..."
    
    update_npm_tools
    update_python_tools
    update_go_tools
    update_binary_releases
    
    log_step "Update process completed. Starting verification..."
    
    if verify_installation; then
        test_tools
        log_info ""
        log_info "🎉 Update completed successfully!"
        log_info "Tools installed to: $INSTALL_DIR"
        
        if [[ -d "$BACKUP_DIR" ]]; then
            read -p "Update was successful. Remove backup directory '$BACKUP_DIR'? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$BACKUP_DIR"
                log_info "Backup removed"
            else
                log_info "Backup kept at $BACKUP_DIR"
            fi
        fi
        exit 0
    else
        log_error "Update failed during verification stage."
        exit 1
    fi
}

# Trap for failure
trap 'restore_backup' ERR

# Run main function
main "$@"
