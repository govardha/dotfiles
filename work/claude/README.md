# Claude Dotfiles

Defensive hooks, approved-command allowlists, and role-based settings for Claude Code across team profiles.

## Features

- **Role-based profiles** — six preconfigured profiles with progressive guards (base → infra-ops)
- **Approved-command allowlists** — granular Bash permission control without prompt fatigue
- **Defensive hooks** — stateless guards for bash, file writes, git, YAML, and CDK operations
- **Team memory** — baseline constraints, practices, and reference documentation
- **Idempotent installer** — safe to re-run; backs up modified user files with timestamps
- **Settings merge system** — layered profiles (common + role-specific) built at distribution time

## Profiles

| Profile | Use Case | Guards |
|---|---|---|
| `base` | Everyone (default) | Audit, prompt validation, branch protection |
| `java-dev` | Java/Spring Boot | Format on save, Checkstyle, Maven discipline |
| `sysops` | On-prem sysops, no sudo | Bash safeguards, write path enforcement, loop detection |
| `k8s-devops` | Kubernetes/Helm/Argo | Manifest validation, kubectl dry-run, prod context block |
| `aws-devops` | AWS CDK (Python) | IAM wildcard block, removal policy, account guards |
| `infra-ops` | Combined ops (sysops + k8s + AWS) | All guards stacked, git-repo-aware writes |

## Install

```bash
# Clone to ~/src/dotfiles (or wherever your dotfiles live)
git clone <your-repo> ~/src/dotfiles

# Install a profile
bash ~/src/dotfiles/claude/install.sh base
bash ~/src/dotfiles/claude/install.sh sysops
bash ~/src/dotfiles/claude/install.sh k8s-devops
bash ~/src/dotfiles/claude/install.sh aws-devops
bash ~/src/dotfiles/claude/install.sh infra-ops
```

## Permission Allowlists

Each profile includes an **approved-commands** allowlist that pre-approves safe, commonly-used commands. Matched commands bypass permission prompts.

- **built-in**: core utilities (cd, ls, grep, find, git, npm, pip, docker)
- **profile-specific**: role-appropriate tools (kubectl, helm, aws, cdk, mvn)
- **customizable**: edit `~/.claude/settings.json` to extend per user

```bash
# View your approved commands
cat ~/.claude/settings.json | jq '.approved_commands'

# Add custom commands (user settings persist across profile installs)
```

## Environment Variables

Set these in your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# AWS DevOps: pipe-separated prod account IDs
export PROD_ACCOUNT_IDS="123456789012|987654321098"

# Audit log location (optional, defaults to ~/.claude/logs/audit.jsonl)
export AUDIT_LOG="/var/log/claude/audit.jsonl"

# Bitbucket on-prem credentials (optional, for PR creation)
export BKT_HOST="https://devtools.miamiholdings.corp/bitbucket"
export BKT_TOKEN="your-personal-access-token"
```

## How It Works

### Settings Merge (Build-Time)

Source files (`.src.json`) define profile-specific hooks and settings. The build system merges:
- `common-settings.src.json` (all profiles get these)
- `<profile>-settings.src.json` (role-specific additions)

Output: consolidated `.json` files (pre-built, no runtime Python needed)

```bash
# Rebuild after editing .src.json files
python3 claude/settings/build-settings.py
```

### Idempotent Installation

- Hash-tracked files (skip if unchanged)
- Backup strategy (modified files backed up with timestamp, not overwritten)
- Dry-run support (`install.sh --dry-run <profile>`)
- Profile switching (users can install multiple profiles; new hooks are added)

### Git Hooks

Claude Code commits get a co-author footer automatically; human commits stay clean:

- **prepare-commit-msg** — Global git hook (installed to `~/.git-hooks/`)
  - If `CLAUDE_CODE=1` env var is set → adds Claude footer
  - If not set → commit has no footer (human-made)
  - Applies to all repos globally
- **inject-claude-env.sh** — Claude Code hook
  - Auto-injects `CLAUDE_CODE=1` before git commits
  - No manual setup needed

## Team Memory

Every user gets baseline team memories during install:
- **constraints.md** — hard safety rules (never commit to main/master, never commit secrets)
- **team_practices.md** — code style and git discipline
- **reference_links.md** — documentation and tools (grows as you learn)

These are shared baseline; users can add personal memories as they get comfortable with Claude Code.

## Repo Layout

```
claude/
├── CLAUDE.md                    # User-facing coding standards
├── README.md                    # This file
├── INSTALL.md                   # Detailed installation guide
├── HOOKS.md                     # Hook behavior and guards catalog
├── install.sh                   # Idempotent profile installer
├── memory/                      # Team-wide baseline memories
│   ├── MEMORY.md
│   ├── constraints.md
│   ├── team_practices.md
│   └── reference_links.md
├── settings/
│   ├── build-settings.py        # Merge common + profile → .json
│   ├── common-settings.src.json # Source: all profiles
│   ├── *-settings.src.json      # Sources: role-specific additions
│   └── *-settings.json          # Built: merged, committed
├── hooks/
│   ├── common/                  # Audit, guards, session (all profiles)
│   ├── global/                  # prepare-commit-msg (git hook)
│   ├── sysops/
│   ├── k8s-devops/
│   ├── aws-devops/
│   └── infra-ops/
├── agents/                      # Claude Code agent definitions
└── org/                         # Org-wide settings (admin-deployed)
```

## Documentation

- **INSTALL.md** — Step-by-step installation, profile selection guide
- **HOOKS.md** — Detailed hook behavior, exit codes, what each guard does
- **CLAUDE.md** — Coding standards and git workflow for users
- **../../CLAUDE.md** — Project maintainer guide (this repo's development)

## Common Commands

```bash
# Preview what will be installed
bash install.sh --dry-run infra-ops

# Install a profile
bash install.sh sysops

# Test a hook locally
bash hooks/sysops/bash-guard.sh "Bash" "rm -rf /important"

# Rebuild settings after editing .src.json files
python3 settings/build-settings.py

# View what's installed in your Claude Code
cat ~/.claude/settings.json | jq .
```
