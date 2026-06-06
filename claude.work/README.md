# Claude Dotfiles

Hooks, agents, and settings for Claude Code across team profiles.

## Profiles

| Profile | Who | Key Guards |
|---|---|---|
| `infra-ops` | Sysops + k8s + AWS (combined) | All guards stacked, git-repo-aware writes |
| `sysops` | On-prem sysops, no sudo | Write path enforcement, loop detection, secrets hygiene |
| `k8s-devops` | On-prem k8s/Helm/Argo | Manifest quality, kubectl dry-run, prod context block |
| `aws-devops` | AWS CDK Python | IAM wildcard block, removal policy, prod account block |
| `java-dev` | Java/Spring Boot | Format on save, Checkstyle, Maven discipline |
| `base` | Everyone else | Prompt guard, audit log only |

## Install

```bash
# Clone to ~/src/dotfiles (or wherever your dotfiles live)
git clone <your-repo> ~/src/dotfiles

# Install a profile
bash ~/src/dotfiles/claude/install.sh infra-ops    # recommended for you
bash ~/src/dotfiles/claude/install.sh sysops
bash ~/src/dotfiles/claude/install.sh k8s-devops
bash ~/src/dotfiles/claude/install.sh aws-devops
bash ~/src/dotfiles/claude/install.sh java-dev
bash ~/src/dotfiles/claude/install.sh base
```

## Environment Variables

Set these in your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# AWS DevOps: pipe-separated prod account IDs
export PROD_ACCOUNT_IDS="123456789012|987654321098"

# Audit log location (optional, defaults to ~/.claude/logs/audit.jsonl)
export AUDIT_LOG="/var/log/claude/audit.jsonl"
```

## Adding a New Profile

1. Add hooks to `hooks/<profile>/`
2. Add `settings/<profile>-settings.json`
3. Add agent to `agents/<profile>.md`
4. Add case to `install.sh`

## Git Hooks

Claude Code commits get a co-author footer automatically; human commits stay clean:

- **prepare-commit-msg** — Global git hook that detects when Claude is committing
  - If `CLAUDE_CODE=1` env var is set → adds Claude footer
  - If not set → commit has no footer (human-made)
  - Installed to `~/.git-hooks/` and applies to all repos globally

## Team Memory

Every user gets baseline team memories during install:
- **constraints.md** — hard safety rules (never commit to main/master, never commit secrets)
- **team_practices.md** — code style and git discipline
- **reference_links.md** — documentation and tools (grows as you learn)

These are shared baseline; users can add personal memories later as they get comfortable with Claude Code.

## Repo Layout

```
claude/
├── CLAUDE.md
├── README.md
├── install.sh
├── memory/              # team-wide baseline memories
│   ├── MEMORY.md
│   ├── constraints.md
│   ├── team_practices.md
│   └── reference_links.md
├── settings/
├── hooks/
│   ├── common/          # all profiles
│   ├── infra-ops/       # combined sysops+k8s+aws
│   ├── sysops/
│   ├── k8s-devops/
│   └── aws-devops/
└── agents/
```
