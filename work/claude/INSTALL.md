# Claude Dotfiles Installation Guide

## Overview

The `install.sh` script sets up Claude Code profiles with defensive hooks, guards, and team baselines. **It is fully idempotent** — safe to run multiple times without data loss or surprises.

## Quick Start

```bash
# Install a profile (idempotent)
bash install.sh infra-ops

# Preview changes without applying
bash install.sh --dry-run infra-ops

# Re-run (only updates changed files)
bash install.sh infra-ops
```

## Profiles

| Profile | Use Case | Includes |
|---------|----------|----------|
| `base` | All users (default) | prompt-guard, audit, branch-guard |
| `sysops` | System operations (no sudo) | bash-guard, write-guard, settings |
| `infra-ops` | Infrastructure (k8s + AWS + sysops) | bash-guard, write-guard, yaml-guard, cdk-python-guard |
| `k8s-devops` | Kubernetes operations | bash-guard, yaml-guard, helm guards |
| `aws-devops` | AWS CDK development | bash-guard, cdk-python-guard, AWS account checks |
| `java-dev` | Java development | base settings only |

## How Idempotency Works

### File State Detection

Each file's state is tracked via **MD5 hash**:

1. **File doesn't exist** → copy it
2. **File exists, hashes match** → skip (report as "unchanged")
3. **File exists, hashes differ** → back up old file, then copy new one

### Backup Location

Old files are backed up to:
```
~/.claude/backups/YYYYMMDD_HHMMSS/
```

Example:
```
~/.claude/backups/20260515_082501/
├── settings.json
├── bash-guard.sh
└── write-guard.sh
```

**Why timestamps?**
- Preserves multiple install snapshots (audit trail)
- Easy to find old configs (date = version)
- No backups overwrite each other
- Users can manually merge settings if needed

## Behavior: First Run vs. Subsequent Runs

### First Run
```bash
$ bash install.sh infra-ops
✓ Installed profile 'infra-ops' → /home/user/.claude
  Updated: 5 files
  Unchanged: 8 files
  Total: 13 files checked
```

### Second Run (No Changes)
```bash
$ bash install.sh infra-ops
✓ All files current. Profile 'infra-ops' → /home/user/.claude
  Unchanged: 13 files
```

### Second Run (You Modified settings.json)
```bash
$ bash install.sh infra-ops
✓ Installed profile 'infra-ops' → /home/user/.claude
  Updated: 1 file
  Backed up: 1 file → /home/user/.claude/backups/20260515_090000/
  Unchanged: 12 files
```

After the backup, you can merge your changes:
```bash
# See what changed
diff ~/.claude/backups/20260515_090000/settings.json ~/.claude/settings.json

# Manually merge if needed
```

## Dry-Run Mode

Preview all changes without applying:
```bash
bash install.sh --dry-run infra-ops
```

Output shows exactly what would change:
```
✓ DRY RUN: Install profile 'infra-ops' to /home/user/.claude
  Would update: 2 files
  Would back up: 1 file → /home/user/.claude/backups/20260515_082501/
  Unchanged: 11 files
  Total: 13 files checked
```

Safe to run anytime — **no changes are made**.

## Git Hook Installation

The script sets up a global git hook to auto-inject the Claude footer:

1. Reads/sets `git config --global core.hooksPath`
2. If not set, uses `~/.git-hooks` and configures git to point there
3. Installs `prepare-commit-msg` hook
4. All Claude commits automatically get `Co-Authored-By: Claude <noreply@anthropic.com>`

See [CLAUDE.md](CLAUDE.md) for footer details.

## What Gets Installed

### Global (All Profiles)
- `~/.claude/hooks/` — common hooks (audit, branch-guard, prompt-guard, session-start)
- `~/.claude/settings.json` — profile-specific Claude Code configuration
- `~/.claude/CLAUDE.md` — coding style guide (global instructions)
- `~/.claude/memory/` — team baseline memory files
- `~/.claude/agents/` — agent definitions
- `~/.claude/.profile` — audit trail (profile name and install timestamp)
- `~/.git-hooks/prepare-commit-msg` — git hook for Claude footer

### Profile-Specific
- `bash-guard.sh` — blocks dangerous bash commands (runaway loops, credentials, prod ops)
- `write-guard.sh` — restricts writes to safe paths (`/home/$USER`, `/apps/$USER`, `/tmp`, etc.)
- `yaml-guard.sh` — validates YAML syntax before executing
- `cdk-python-guard.sh` — blocks CDK deploy without review

## Profile Audit Trail

After installation, check which profile was bootstrapped:

```bash
cat ~/.claude/.profile
```

Output:
```
profile=infra-ops
installed=2026-05-15T13:19:43Z
```

This is useful when onboarding new users or auditing team baseline installations.

## Troubleshooting

### "All files current" but you expected updates
The files didn't change. Verify:
```bash
# Check if settings file has new fields
diff <(md5sum ~/.claude/backups/*/settings.json)
```

If you modified settings.json and want the team defaults:
```bash
# Back up your customizations
cp ~/.claude/settings.json ~/.claude/settings.json.custom

# Re-install (will back up and restore defaults)
bash install.sh infra-ops

# Manually merge your custom settings back in
```

### "Write to ... outside allowed paths"
The write-guard is blocking a write. Check:
- Is the path in `/home/$USER`, `/apps/$USER`, `/tmp`, `/opt/...`?
- Is the path inside a git repo? (Write guard allows all git repos)
- Update write-guard.sh to add new safe paths

Example: to allow `/srv/data/`:
```bash
# Edit write-guard.sh
allowed_prefixes=(
  "/home/${USER}"
  "/apps/${USER}"
  "/srv/data"
  ...
)
```

### "Staged changes exist but are not committed" during git push
The bash-guard caught uncommitted staged changes. This prevents the incident where you pushed without committing everything.

Fix:
```bash
git status
git add <missing-files>
git commit -m "message"
git push
```

### Want to keep old backups cleaned up
Backups go to `~/.claude/backups/TIMESTAMP/`. You can clean up old ones:
```bash
# Keep last 7 days
find ~/.claude/backups -type d -mtime +7 -exec rm -rf {} \;

# Or clean all
rm -rf ~/.claude/backups/*
```

## For Power Users: Customization Workflow

1. Run install: `bash install.sh infra-ops`
2. Customize `~/.claude/settings.json`, `~/.claude/memory/`, etc.
3. Next team update: `bash install.sh infra-ops`
   - Your customizations are backed up
   - Team defaults are restored
   - You manually merge changes back

Alternative: keep backups as version history:
```bash
# Check what changed between versions
diff ~/.claude/backups/20260501_100000/settings.json \
     ~/.claude/backups/20260515_082501/settings.json
```

## File Permissions

The install script automatically makes hook files executable (`chmod +x`).

If a hook isn't running, check permissions:
```bash
ls -la ~/.claude/hooks/
# Should show -rwxr-xr-x for all .sh files
```

## Hooks and Their Purposes

See [HOOKS.md](HOOKS.md) for detailed documentation of each guard and what it checks.

**Summary:**
- **bash-guard.sh** — Bash command safety (loops, deletes, credentials)
- **write-guard.sh** — File write safety (allowed paths)
- **yaml-guard.sh** — YAML syntax validation
- **cdk-python-guard.sh** — CDK Python deployment safety
- **branch-guard.sh** — Git branch checks
- **prompt-guard.sh** — Request-level safety
- **audit.sh** — Command logging

## Testing Your Installation

### Test git-push-guard
```bash
cd /tmp && mkdir test-repo && cd test-repo
git init
echo "test" > file.txt && git add file.txt && git commit -m "init"

# Stage a change without committing
echo "new" > file2.txt && git add file2.txt

# Try to push (guard will block with message about staged changes)
git push origin main 2>&1 || echo "Guard blocked as expected"
```

### Test write-guard
```bash
# Allowed: writes inside git repos and /home/$USER
cat > ~/allowed.txt  # OK

# Blocked: writes outside allowed paths
echo "test" > /root/not-allowed.txt  # Will be blocked
```

## Next Steps

1. Review active guards: `cat ~/.claude/hooks/bash-guard.sh`
2. Customize settings: `nano ~/.claude/settings.json`
3. Add team memories: `ls ~/.claude/memory/`
4. Set up your IDE: See Claude Code documentation for IDE extensions
