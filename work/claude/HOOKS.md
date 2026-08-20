# Hooks & Settings Architecture

How Claude Code hooks work, what each one does, and how user-level settings
layer with the org-level `org/settings.json`.

## Settings Hierarchy

Claude Code merges settings from multiple layers (highest priority wins):

```
┌─────────────────────────────────────────────┐
│  Project (.claude/settings.json in repo)    │  ← per-repo overrides
├─────────────────────────────────────────────┤
│  User (~/.claude/settings.json)             │  ← installed by install.sh
├─────────────────────────────────────────────┤
│  Org (org/settings.json pushed by admin)    │  ← team-wide policy
└─────────────────────────────────────────────┘
```

- **Org** sets the floor: model defaults, cost controls, permission denials,
  and company announcements. Users cannot override org denials.
- **User** adds profile-specific hooks and preferences on top.
- **Project** can add repo-specific hooks (e.g. a monorepo lint gate).

## What org/settings.json Controls

| Setting | Purpose |
|---|---|
| `model` / `availableModels` | Default to Haiku, allow Sonnet/Opus when needed |
| `disallowDefaultModel` | Prevent accidental Opus usage from the model picker |
| `env.CLAUDE_CODE_EFFORT_LEVEL` | Default to medium effort (cost control) |
| `companyAnnouncements` | Cost awareness banner shown every session |
| `permissions.defaultMode` | `acceptEdits` — auto-accept file edits, prompt on bash |
| `permissions.disableBypassPermissionsMode` | Block `--dangerously-skip-permissions` |
| `permissions.deny` | Hard deny: secrets files, force push, `rm -rf /` |

The org file is the safety net. Even if a user's hooks fail or are misconfigured,
the org denials still block reading `.env`, `~/.aws/credentials`, `~/.ssh/*`, and
destructive git/rm commands.

## Hook Events

| Event | When it fires | Use case |
|---|---|---|
| `SessionStart` | Once when Claude session begins | Inject environment context |
| `UserPromptSubmit` | Before processing user's prompt | Block oversized/overbroad prompts |
| `PreToolUse` | Before Claude executes a tool | Guard bash commands, file writes |
| `PostToolUse` | After a tool completes | Audit logging |

## Hook Inventory

### Common (all profiles)

| Hook | Event | Behavior |
|---|---|---|
| `session-start.sh` | SessionStart | Detects host environment (prod/staging/dev), injects context rules |
| `prompt-guard.sh` | UserPromptSubmit | Blocks prompts >8000 chars, blocks "summarize entire codebase" patterns, injects cost reminder on bulk reads |
| `audit.sh` | PostToolUse (async) | Appends JSONL log entry with timestamp, user, host, tool, target |
| `git-guard.sh` | PreToolUse | Blocks commits/adds on main/master, blocks push with uncommitted staged changes |

### infra-ops (combined profile)

| Hook | Event | Matcher | What it blocks |
|---|---|---|---|
| `bash-guard.sh` | PreToolUse | `Bash` | Unbounded loops, mass deletes in shared paths, literal credentials, AWS key leaks, `cdk deploy/destroy`, s3 deletes without `--dryrun`, prod account usage, kubectl mutating ops without `--dry-run`, prod k8s context, helm without dry-run, argocd prod sync |
| `write-guard.sh` | PreToolUse | `Write\|Edit` | Writes outside git repos and outside allowed sysops paths |
| `yaml-guard.sh` | PreToolUse | `Write\|Edit` | `:latest` image tags, missing resource limits, missing namespace, prod namespace in manifests |
| `cdk-python-guard.sh` | PreToolUse | `Write\|Edit` | Wildcard IAM, missing removal_policy on stateful resources, hardcoded account IDs, hardcoded regions |

### sysops (standalone)

| Hook | Event | Matcher | What it blocks |
|---|---|---|---|
| `bash-guard.sh` | PreToolUse | `Bash` | Unbounded loops, mass deletes, literal credentials, cron reminders |
| `write-guard.sh` | PreToolUse | `Write\|Edit` | Writes outside `/home/$USER`, `/tmp`, `/opt/scripts`, `/opt/monitoring`, `/opt/cronjobs` |

### k8s-devops (standalone)

| Hook | Event | Matcher | What it blocks |
|---|---|---|---|
| `bash-guard.sh` | PreToolUse | `Bash` | kubectl mutating without `--dry-run`, prod context, helm without dry-run, argocd prod sync |
| `yaml-guard.sh` | PreToolUse | `Write\|Edit` | `:latest` tags, missing resources block, missing namespace, prod namespace |

### aws-devops (standalone)

| Hook | Event | Matcher | What it blocks |
|---|---|---|---|
| `bash-guard.sh` | PreToolUse | `Bash` | `cdk deploy/destroy`, prod account, s3 delete without `--dryrun`, literal AWS keys |
| `cdk-python-guard.sh` | PreToolUse | `Write\|Edit` | Wildcard IAM, missing removal_policy, hardcoded account IDs, hardcoded regions |

## How Hooks Complement Org Settings

```
Org settings.json                    User hooks (installed per profile)
─────────────────                    ─────────────────────────────────
Hard deny on secrets files     +     bash-guard blocks credentials in commands
Hard deny on force push        +     bash-guard blocks prod context/account
Hard deny on rm -rf /          +     write-guard restricts write paths
Model/cost defaults            +     prompt-guard blocks oversized prompts
                                     yaml-guard enforces manifest quality
                                     cdk-python-guard enforces IAM discipline
                                     audit.sh logs everything
```

Org settings are **passive denials** — they say "never allow X" regardless of context.
User hooks are **active guards** — they inspect the actual command/content and make
context-aware decisions (is this a prod account? is this file in a git repo?).

Together they form defense in depth: org catches the catastrophic mistakes,
hooks catch the domain-specific ones.

## Hook Exit Codes

| Code | Meaning |
|---|---|
| `0` | Allow — tool proceeds normally |
| `2` | Block — tool execution is prevented, message shown to Claude |

Hooks can also print to stdout without blocking (exit 0) to inject context
or reminders into the conversation.
