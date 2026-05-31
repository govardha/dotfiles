#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ssh/install.sh — Generate ~/.ssh/config.d/ from nodes.conf
# Supports macOS, Linux, MSYS2. Handles IPv4/IPv6 address families.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODES_CONF="$SCRIPT_DIR/nodes.conf"
SSH_DIR="$HOME/.ssh"
CONF_DIR="$SSH_DIR/config.d"
OVERRIDES="$CONF_DIR/90-lan-overrides"

die() { echo "ERROR: $*" >&2; exit 1; }

# --- OS Detection ---
detect_os() {
    case "$(uname -s)" in
        Darwin)            OS="macos" ;;
        Linux)             OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) OS="msys2" ;;
        *)                 OS="linux" ;;
    esac
}

# --- Ping command for Match exec (OS-aware) ---
match_ping_cmd() {
    local ip="$1"
    case "$OS" in
        macos) echo "ping -c1 -W 1000 $ip >/dev/null 2>&1" ;;
        msys2) echo "ping -n 1 -w 1000 $ip >/dev/null 2>&1" ;;
        *)     echo "ping -c1 -W1 $ip >/dev/null 2>&1" ;;
    esac
}

# --- Write 00-defaults based on OS ---
write_defaults() {
    local f="$CONF_DIR/00-defaults"
    cat > "$f" <<'COMMON'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
COMMON
    case "$OS" in
        macos) echo '    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"' >> "$f" ;;
        linux) echo '    IdentityAgent ~/.1password/agent.sock' >> "$f" ;;
    esac
    chmod 600 "$f"
}

# --- Generate config from nodes.conf ---
generate() {
    [[ -f "$NODES_CONF" ]] || die "nodes.conf not found at $NODES_CONF
Copy nodes.conf.example to nodes.conf and fill in your values."

    mkdir -p "$CONF_DIR"
    chmod 700 "$SSH_DIR"

    # Ensure main config has Include
    if [[ ! -f "$SSH_DIR/config" ]] || ! grep -q 'Include.*config\.d' "$SSH_DIR/config"; then
        echo 'Include ~/.ssh/config.d/*' > "$SSH_DIR/config"
        chmod 600 "$SSH_DIR/config"
    fi

    write_defaults

    # Clear generated group files and overrides
    local override_lines=()
    declare -A group_files=()

    local current_group=""
    while IFS= read -r line; do
        # Skip comments and blanks
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Group header
        if [[ "$line" =~ ^\[group:(.+)\]$ ]]; then
            current_group="${BASH_REMATCH[1]}"
            group_files["$current_group"]=""
            continue
        fi

        [[ -z "$current_group" ]] && continue

        # Parse node line: alias hostname user [af] [lan_ip]
        read -r alias hostname user af lan_ip <<< "$line"
        [[ -z "$alias" || -z "$hostname" || -z "$user" ]] && continue

        # Build host block
        local block=""
        block+="Host $alias"$'\n'
        if [[ -n "$af" && "$af" != "-" ]]; then
            block+="    AddressFamily $af"$'\n'
        fi
        block+="    HostName $hostname"$'\n'
        block+="    User $user"$'\n'

        group_files["$current_group"]+="$block"$'\n'

        # LAN override
        if [[ -n "$lan_ip" && "$lan_ip" != "-" ]]; then
            local pcmd
            pcmd=$(match_ping_cmd "$lan_ip")
            override_lines+=("")
            override_lines+=("Match host $alias exec \"$pcmd\"")
            override_lines+=("    HostName $lan_ip")
        fi
    done < "$NODES_CONF"

    # Write group files
    for group in "${!group_files[@]}"; do
        local target="$CONF_DIR/$group"
        printf '%s' "${group_files[$group]}" > "$target"
        chmod 600 "$target"
        echo "Generated $target"
    done

    # Write overrides
    {
        echo "# LAN overrides — only active when on home network"
        for ol in "${override_lines[@]}"; do
            echo "$ol"
        done
    } > "$OVERRIDES"
    chmod 600 "$OVERRIDES"
    echo "Generated $OVERRIDES"

    echo "Done. SSH config generated for OS=$OS"
}

# --- Main ---
detect_os

case "${1:-generate}" in
    generate) generate ;;
    clean)
        rm -f "$CONF_DIR"/[0-9]*-* "$CONF_DIR/00-defaults" "$OVERRIDES"
        echo "Cleaned generated SSH config files."
        ;;
    *)
        echo "Usage: $0 [generate|clean]"
        echo "  generate  — (default) Generate ~/.ssh/config.d/ from nodes.conf"
        echo "  clean     — Remove generated config files"
        ;;
esac
