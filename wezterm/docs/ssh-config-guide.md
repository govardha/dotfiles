# SSH Config Guide

Recommended SSH config structure for use with this WezTerm configuration. Uses `Include` directives for modularity and `Match exec` for automatic LAN/Tailscale switching.

## Overview

The WezTerm `nodes_config.lua` module parses `~/.ssh/config` (including files referenced by `Include` directives) to auto-discover hosts and group them in the launch menu and workspaces. This guide describes how to structure your SSH config to work well with that parser.

## Directory Structure

```
~/.ssh/
├── config                  # Main config — just Include directives
├── config.d/
│   ├── 00-defaults         # Global defaults
│   ├── 10-depot-nodes      # Depot node definitions
│   ├── 20-vpn-nodes        # VPN fleet definitions
│   ├── 30-other-nodes      # Other hosts
│   └── 90-lan-overrides    # LAN fallback via Match exec
└── keys/                   # SSH keys (optional organization)
```

Files in `config.d/` are processed in lexical order (numeric prefixes control ordering). Host definitions must come before `Match` overrides, which is why overrides are in `90-*`.

## Main Config

`~/.ssh/config`:

```ssh-config
# Load all modular config files
Include ~/.ssh/config.d/
```

That's it. All host definitions live in `config.d/`.

## config.d/00-defaults

Global settings applied to all connections:

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
```

### macOS with 1Password SSH Agent

If using 1Password as your SSH agent on macOS, add:

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

### Linux with 1Password SSH Agent

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentitiesOnly yes
    IdentityAgent ~/.1password/agent.sock
```

## config.d/10-depot-nodes

Depot nodes — x86 machines. HostName uses Tailscale MagicDNS FQDN as the default:

```ssh-config
Host rinku-depot
    HostName rinku-depot.pigeon-hamlet.ts.net
    User ubuntu

Host rinku-depot2
    HostName rinku-depot2.pigeon-hamlet.ts.net
    User ubuntu
```

Add more depot nodes following the same pattern. The WezTerm config groups these using the `depot` pattern match or explicit lists in `nodes_config.lua` → `get_group_config()`.

## config.d/20-vpn-nodes

VPN fleet — OCI ARM nodes:

```ssh-config
Host vpn
    HostName vpn.pigeon-hamlet.ts.net
    User ubuntu

Host vpn2
    HostName vpn2.pigeon-hamlet.ts.net
    User ubuntu

Host vpn3
    HostName vpn3.pigeon-hamlet.ts.net
    User ubuntu

Host vpn4
    HostName vpn4.pigeon-hamlet.ts.net
    User ubuntu
```

WezTerm groups these using the `^vpn%d*$` pattern in `get_group_config()`.

## config.d/30-other-nodes

Hosts that don't fit the depot/vpn patterns:

```ssh-config
Host what
    HostName what.pigeon-hamlet.ts.net
    User gundan

Host imac-ubuntu
    HostName imac-ubuntu.pigeon-hamlet.ts.net
    User govardha
```

WezTerm groups these via the explicit list in `get_group_config()`.

## config.d/90-lan-overrides

When you're on your home LAN, these `Match exec` blocks override the Tailscale FQDN with the local LAN IP. The `ping` command tests if the LAN IP is reachable with a 1-second timeout — if it is, you're home and the override applies.

```ssh-config
# LAN overrides — only active when on home network
# Replace 192.168.x.x with actual LAN IPs of each node

Match host rinku-depot exec "ping -c1 -W1 192.168.1.100 >/dev/null 2>&1"
    HostName 192.168.1.100

Match host rinku-depot2 exec "ping -c1 -W1 192.168.1.101 >/dev/null 2>&1"
    HostName 192.168.1.101

Match host what exec "ping -c1 -W1 192.168.1.102 >/dev/null 2>&1"
    HostName 192.168.1.102

Match host imac-ubuntu exec "ping -c1 -W1 192.168.1.103 >/dev/null 2>&1"
    HostName 192.168.1.103
```

How it works:
- **At home**: `ping` succeeds → SSH uses the LAN IP (direct, no Tailscale overhead)
- **Away**: `ping` fails → SSH falls back to the Tailscale FQDN from the Host definition
- **Latency**: The 1-second ping timeout adds negligible delay when away (the ping fails fast on a different network)

Only add overrides for nodes that are on your home LAN. Remote depot nodes (at family members' homes) and VPN nodes (OCI cloud) don't need LAN overrides — they're always accessed via Tailscale.

## How WezTerm Parses This

The `nodes_config.lua` module:

1. Opens `~/.ssh/config`
2. Follows `Include` directives recursively (expands globs like `~/.ssh/config.d/*`)
3. Extracts `Host` entries (skipping wildcards like `Host *`)
4. Groups hosts by pattern or explicit list (configured in `get_group_config()`)
5. Populates the launch menu and workspace tabs

The parser reads `Host`, `HostName`, and `User` fields. It ignores `Match` blocks (those are handled by SSH itself at connection time).

## Adding a New Node

1. Add a `Host` block to the appropriate file in `~/.ssh/config.d/`
2. If it's on your home LAN, optionally add a `Match` override in `90-lan-overrides`
3. If it doesn't match an existing group pattern, add it to the explicit list in `nodes_config.lua` → `get_group_config()`
4. Reload WezTerm — the node appears in the launch menu automatically

## Troubleshooting

**Node not appearing in WezTerm launch menu:**
- Verify the Host entry exists: `grep -r "^Host " ~/.ssh/config.d/`
- Check that the host alias doesn't contain wildcards (`*`, `?`)
- Verify the group pattern matches: check `get_group_config()` in `nodes_config.lua`

**LAN override not working:**
- Test the ping manually: `ping -c1 -W1 192.168.x.x`
- Verify the Match syntax: `ssh -vvv <host>` shows which config blocks matched
- Ensure `90-lan-overrides` is loaded after the Host definitions (numeric prefix ordering)

**SSH connection uses wrong hostname:**
- Run `ssh -G <host> | grep hostname` to see the resolved hostname
- This shows the final hostname after all Match processing
