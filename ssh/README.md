# ssh/ — SSH Config Generator

Generates `~/.ssh/config.d/` from a private `nodes.conf` file so this repo can stay public without exposing hostnames, IPs, or network topology.

## Setup

```bash
cp ssh/nodes.conf.example ssh/nodes.conf
# Edit nodes.conf with your actual node definitions
./ssh/install.sh
```

## nodes.conf format

```
[group:10-depot-nodes]
alias    hostname                        user    af       lan_ip
mybox    mybox.my-tailnet.ts.net         ubuntu  -        192.168.1.92

[group:30-other-nodes]
seedbox  seed.example.com                myuser  inet
seedbox6 seed.example.com                myuser  inet6
```

Fields:
- **alias** — what you type (`ssh <alias>`)
- **hostname** — FQDN or IP
- **user** — remote username
- **af** — address family: `inet` (IPv4 only), `inet6` (IPv6 only), or `-`/omit for dual-stack
- **lan_ip** — optional LAN IP; generates a `Match` block that auto-switches when reachable

## Commands

```bash
./ssh/install.sh           # generate (default)
./ssh/install.sh generate  # same as above
./ssh/install.sh clean     # remove generated files from ~/.ssh/config.d/
```

## What gets generated

| File | Contents |
|------|----------|
| `~/.ssh/config.d/00-defaults` | OS-specific defaults (1Password agent, keepalive) |
| `~/.ssh/config.d/10-depot-nodes` | Nodes from `[group:10-depot-nodes]` |
| `~/.ssh/config.d/20-vpn-nodes` | Nodes from `[group:20-vpn-nodes]` |
| `~/.ssh/config.d/30-other-nodes` | Nodes from `[group:30-other-nodes]` |
| `~/.ssh/config.d/90-lan-overrides` | Auto-generated LAN ping-switch rules |
