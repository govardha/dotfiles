#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ssh-config-setup.sh — Create & manage modular ~/.ssh/config structure
# Handles macOS, Ubuntu/Linux, and Windows MSYS2/Git Bash
# =============================================================================

SSH_DIR="$HOME/.ssh"
CONF_DIR="$SSH_DIR/config.d"
KEYS_DIR="$SSH_DIR/keys"
OVERRIDES="$CONF_DIR/90-lan-overrides"

# --- OS Detection ---
detect_os() {
    case "$(uname -s)" in
        Darwin)  OS="macos" ;;
        Linux)   OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) OS="msys2" ;;
        *)       OS="linux" ;;  # fallback
    esac
    echo "Detected OS: $OS"
}

# --- Ping flag differs per OS ---
ping_timeout_flag() {
    case "$OS" in
        macos)  echo "-W 1000" ;;  # macOS -W is milliseconds
        msys2)  echo "-w 1000" ;;  # Windows ping uses -w ms
        *)      echo "-W1" ;;      # Linux -W is seconds
    esac
}

ping_count_flag() {
    case "$OS" in
        msys2) echo "-n 1" ;;
        *)     echo "-c1" ;;
    esac
}

# --- Build the ping command for Match exec ---
match_ping_cmd() {
    local ip="$1"
    local cnt; cnt=$(ping_count_flag)
    local tmout; tmout=$(ping_timeout_flag)
    echo "ping $cnt $tmout $ip >/dev/null 2>&1"
}

# --- Create directory structure & base files ---
cmd_init() {
    echo "Initializing SSH config structure..."
    mkdir -p "$CONF_DIR" "$KEYS_DIR"
    chmod 700 "$SSH_DIR"

    # Main config
    if [[ ! -f "$SSH_DIR/config" ]]; then
        cat > "$SSH_DIR/config" <<'EOF'
# Load all modular config files
Include ~/.ssh/config.d/*
EOF
        chmod 600 "$SSH_DIR/config"
        echo "Created $SSH_DIR/config"
    else
        echo "$SSH_DIR/config already exists, skipping"
    fi

    # 00-defaults
    if [[ ! -f "$CONF_DIR/00-defaults" ]]; then
        case "$OS" in
            macos)
                cat > "$CONF_DIR/00-defaults" <<'EOF'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
                ;;
            linux)
                cat > "$CONF_DIR/00-defaults" <<'EOF'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
    IdentityAgent ~/.1password/agent.sock
EOF
                ;;
            msys2)
                cat > "$CONF_DIR/00-defaults" <<'EOF'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
EOF
                ;;
        esac
        chmod 600 "$CONF_DIR/00-defaults"
        echo "Created $CONF_DIR/00-defaults (${OS} variant)"
    else
        echo "$CONF_DIR/00-defaults already exists, skipping"
    fi

    # Seed empty group files if missing
    for f in 10-depot-nodes 20-vpn-nodes 30-other-nodes; do
        if [[ ! -f "$CONF_DIR/$f" ]]; then
            : > "$CONF_DIR/$f"
            chmod 600 "$CONF_DIR/$f"
            echo "Created $CONF_DIR/$f (empty)"
        fi
    done

    # Seed overrides file
    if [[ ! -f "$OVERRIDES" ]]; then
        echo "# LAN overrides — only active when on home network" > "$OVERRIDES"
        chmod 600 "$OVERRIDES"
        echo "Created $OVERRIDES"
    fi

    echo "Done. Structure:"
    find "$SSH_DIR" -maxdepth 2 -not -name "known_hosts*" -not -name "authorized_keys" \
        -not -name "*.pub" -not -name "id_*" | sort | sed "s|$HOME|~|"
}

# --- Add a node ---
cmd_add() {
    local alias="" hostname="" user="ubuntu" group="30-other-nodes" lan_ip=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --alias)    alias="$2";    shift 2 ;;
            --host)     hostname="$2"; shift 2 ;;
            --user)     user="$2";     shift 2 ;;
            --group)    group="$2";    shift 2 ;;
            --lan-ip)   lan_ip="$2";   shift 2 ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
    done

    if [[ -z "$alias" || -z "$hostname" ]]; then
        echo "Usage: $0 add --alias NAME --host FQDN [--user USER] [--group GROUP_FILE] [--lan-ip IP]"
        echo ""
        echo "  --alias    SSH alias (e.g. rinku-depot)"
        echo "  --host     HostName / FQDN (e.g. rinku-depot.pigeon-hamlet.ts.net)"
        echo "  --user     Remote user (default: ubuntu)"
        echo "  --group    Config file in config.d/ (default: other)"
        echo "             Shortcuts: depot=10-depot-nodes, vpn=20-vpn-nodes, other=30-other-nodes"
        echo "  --lan-ip   Optional LAN IP for auto-switching override"
        return 1
    fi

    # Resolve group shortcuts
    case "$group" in
        depot) group="10-depot-nodes" ;;
        vpn)   group="20-vpn-nodes" ;;
        other) group="30-other-nodes" ;;
    esac

    local target="$CONF_DIR/$group"
    if [[ ! -f "$target" ]]; then
        : > "$target"
        chmod 600 "$target"
    fi

    # Check for duplicate
    if grep -q "^Host ${alias}$" "$target" 2>/dev/null; then
        echo "Host '$alias' already exists in $group"
        return 1
    fi

    # Append host block
    {
        [[ -s "$target" ]] && echo ""
        echo "Host $alias"
        echo "    HostName $hostname"
        echo "    User $user"
    } >> "$target"
    echo "Added '$alias' -> $hostname (user=$user) in $group"

    # LAN override
    if [[ -n "$lan_ip" ]]; then
        local ping_cmd; ping_cmd=$(match_ping_cmd "$lan_ip")
        {
            echo ""
            echo "Match host $alias exec \"$ping_cmd\""
            echo "    HostName $lan_ip"
        } >> "$OVERRIDES"
        echo "Added LAN override: $alias -> $lan_ip"
    fi
}

# --- Remove a node ---
cmd_remove() {
    local alias="${1:-}"
    if [[ -z "$alias" ]]; then
        echo "Usage: $0 remove ALIAS"
        return 1
    fi

    local found=0
    # Remove from group files (Host block = Host line + indented lines following it)
    for f in "$CONF_DIR"/*; do
        [[ -f "$f" ]] || continue
        if grep -q "^Host ${alias}$" "$f"; then
            awk -v host="$alias" '
                /^Host / { if ($2 == host) { skip=1; next } else { skip=0 } }
                /^Match / { skip=0 }
                /^[^ \t]/ && !/^Host / && !/^Match / { skip=0 }
                !skip { print }
            ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
            chmod 600 "$f"
            echo "Removed '$alias' from $(basename "$f")"
            found=1
        fi
    done

    # Remove from overrides (Match block)
    if grep -q "Match host ${alias} " "$OVERRIDES" 2>/dev/null; then
        awk -v host="$alias" '
            /^Match host / { if ($3 == host) { skip=1; next } else { skip=0 } }
            /^(Host |Match |[^ \t])/ && !/^Match host / { skip=0 }
            !skip { print }
        ' "$OVERRIDES" > "${OVERRIDES}.tmp" && mv "${OVERRIDES}.tmp" "$OVERRIDES"
        chmod 600 "$OVERRIDES"
        echo "Removed LAN override for '$alias'"
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        echo "Host '$alias' not found in any config file"
        return 1
    fi
}

# --- List all nodes ---
cmd_list() {
    echo "=== SSH Nodes ==="
    for f in "$CONF_DIR"/[0-8]*; do
        [[ -f "$f" ]] || continue
        local hosts; hosts=$(grep "^Host " "$f" 2>/dev/null | awk '{print $2}')
        if [[ -n "$hosts" ]]; then
            echo ""
            echo "[$(basename "$f")]"
            while IFS= read -r h; do
                local hn; hn=$(awk -v host="$h" '
                    /^Host / { cur=$2 }
                    cur==host && /HostName/ { print $2; exit }
                ' "$f")
                local lan=""
                if [[ -f "$OVERRIDES" ]]; then
                    lan=$(awk -v host="$h" '
                        /^Match host / && $3==host { getline; if (/HostName/) print $2 }
                    ' "$OVERRIDES")
                fi
                printf "  %-25s %s" "$h" "$hn"
                [[ -n "$lan" ]] && printf "  (LAN: %s)" "$lan"
                echo ""
            done <<< "$hosts"
        fi
    done
}

# --- Clean: wipe all generated config ---
cmd_clean() {
    echo "This will remove:"
    echo "  $CONF_DIR/*"
    echo "  $SSH_DIR/config (the Include-only main config)"
    echo ""
    read -rp "Continue? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        rm -rf "$CONF_DIR"
        rm -f "$SSH_DIR/config"
        echo "Cleaned. Keys in $KEYS_DIR were preserved."
    else
        echo "Aborted."
    fi
}

# --- Regenerate defaults for current OS ---
cmd_redefaults() {
    rm -f "$CONF_DIR/00-defaults"
    cmd_init 2>/dev/null
    echo "Regenerated 00-defaults for $OS"
}

# --- Usage ---
usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  init                  Create ~/.ssh directory structure and base config files
  add [options]         Add a node
      --alias NAME      SSH alias (required)
      --host  FQDN      Hostname / FQDN (required)
      --user  USER      Remote user (default: ubuntu)
      --group GROUP     depot | vpn | other | filename (default: other)
      --lan-ip IP       LAN IP for auto-switching override
  remove ALIAS          Remove a node from all config files
  list                  List all configured nodes
  clean                 Remove all generated config (preserves keys)
  redefaults            Regenerate 00-defaults for detected OS ($OS)

Examples:
  $0 init
  $0 add --alias mybox --host mybox.tailnet.ts.net --user admin --group depot --lan-ip 192.168.1.50
  $0 remove mybox
  $0 list
EOF
}

# --- Main ---
detect_os

case "${1:-}" in
    init)        cmd_init ;;
    add)         shift; cmd_add "$@" ;;
    remove)      shift; cmd_remove "${1:-}" ;;
    list)        cmd_list ;;
    clean)       cmd_clean ;;
    redefaults)  cmd_redefaults ;;
    *)           usage ;;
esac
