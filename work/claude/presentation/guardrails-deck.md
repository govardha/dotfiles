---
title: Claude Code Guardrails
description: A tour of the settings, hooks, and profiles that keep Claude Code safe by default
audience: Engineers new to Claude Code
source: dotfiles/work/claude
marp: true
paginate: true
---

# Guardrails, Built In

A tour of the settings, hooks, and profiles that keep Claude Code safe by default — so new users can start running real commands on day one, not just reading code.

**Audience** — engineers new to Claude Code
**Source** — `dotfiles/work/claude`

`6 role profiles` · `org → user → project settings` · `4 hook events` · `defense in depth`

---

## Why this exists

### An agent that can act needs boundaries that act too

Claude Code doesn't just suggest — it reads files, edits code, runs shell commands, and commits. That's the whole point. It also means every session has real blast radius, and review-after-the-fact isn't fast enough.

1. **Checks run inline, before the risky step.**
   A hook inspects the actual command or file content and decides in milliseconds — not after something's already deployed.

2. **Guards are quiet until something's actually risky.**
   Routine work — status checks, diffs, edits in a feature branch — never gets interrupted.

3. **Nothing here is about distrust.**
   It's what lets you hand over the keys — prod accounts, kubectl, cdk deploy — with confidence instead of white-knuckling every session.

---

## Settings hierarchy

### Three layers, one floor that never moves

Claude Code merges settings from three places. Project and user layers add and override each other — but org denials are absolute.

| Layer | Where | What it does |
|---|---|---|
| **Project** | `.claude/settings.json` in the repo | Per-repo overrides — e.g. a monorepo's extra lint gate. Highest precedence for anything it defines. |
| **User** | `~/.claude/settings.json` | Installed by `install.sh` for your role profile — bash-guard, write-guard, yaml-guard, cdk-python-guard, memory. |
| **Org** | `org/settings.json`, admin-deployed | Model defaults, cost controls, and hard `permissions.deny` rules: secrets files, force push, `rm -rf /`. |

> **Org sets the floor.** Even if a user's hooks fail, get uninstalled, or are misconfigured, org denials still block reading `.env`, `~/.aws/credentials`, `~/.ssh/*`, and destructive git/rm commands. Users cannot override an org deny.

---

## Hook lifecycle

### Four moments where a hook can speak up

Every hook attaches to one of four events in a session. Most guardrail logic lives in `PreToolUse` — the instant before Claude runs a command or writes a file.

| Event | Fires | Purpose | Example hook |
|---|---|---|---|
| `SessionStart` | Once, at session boot | Detects host environment, injects active rules into context | `session-start.sh` |
| `UserPromptSubmit` | Before your prompt is read | Blocks oversized pastes, flags reckless scope, notes cost on bulk reads | `prompt-guard.sh` |
| `PreToolUse` | Before a tool executes | Inspects the bash command or file content; can allow or block with a reason | `bash-guard.sh` / `branch-guard.sh` / `git-guard.sh` |
| `PostToolUse` | After a tool completes | Fires async — logs what happened without slowing the session down | `audit.sh` |

---

## Defense in depth

### Two different kinds of "no"

Org denials are passive — a static list, blind to context. User hooks are active — they read the actual command and decide. Together they cover both the catastrophic and the domain-specific mistake.

**Org · passive denial**
- Hard deny on reading secrets files (`.env`, `~/.aws/credentials`, `~/.ssh/*`)
- Hard deny on force push
- Hard deny on `rm -rf /`
- Model / cost defaults, `--dangerously-skip-permissions` disabled

**User hooks · active guard**
- `bash-guard` blocks literal credentials, prod account usage, unbounded loops
- `git-guard` blocks add/commit/push on `main`, `master`, `develop` — and pushes with uncommitted staged changes
- `write-guard` restricts writes to safe paths and git repos
- `yaml-guard` / `cdk-python-guard` enforce manifest and IAM discipline
- `audit.sh` logs every tool call, every session

---

## Role profiles

### Guards scale with what you actually touch

One install script, six profiles. Pick the one that matches your work — more than one can be layered.

| Profile | Use case | Guards added |
|---|---|---|
| `base` | Everyone, default | Audit log, prompt validation, branch protection |
| `java-dev` | Java / Spring Boot | Format on save, Checkstyle, Maven discipline |
| `sysops` | On-prem ops, no sudo | Bash safeguards, write-path enforcement, loop detection |
| `k8s-devops` | Kubernetes / Helm / Argo | Manifest validation, kubectl dry-run, prod-context block |
| `aws-devops` | AWS CDK (Python) | IAM wildcard block, removal-policy check, account guard |
| `infra-ops` | Combined ops | Everything above, stacked, git-repo-aware writes |

---

## In the wild

### What a block actually looks like

Five real guards, five real attempts. Each one returns a specific reason and a next step — never a silent no. Notice `branch-guard` and `git-guard` enforce the same "no work on main" rule from two different angles: one stops the file edit, the other stops the git command.

**`branch-guard.sh` — BLOCKED**
```
Edit tool → writing on branch "main"

Cannot write files on main/master.
Create a feature branch first.
```

**`git-guard.sh` — BLOCKED**
```
git push origin main

Cannot push directly to main.

Workflow: merge via pull request
  bkt pr create --target main
  bkt pr merge <pr-id>
```

**`cdk-python-guard.sh` — BLOCKED**
```
actions=["*"] in stack.py

Wildcard IAM action or resource.
Scope permissions to minimum required.
```

**`aws-devops/bash-guard.sh` — BLOCKED**
```
cdk destroy

cdk destroy not permitted via Claude.
Execute manually.
```

**`k8s-devops/yaml-guard.sh` — BLOCKED**
```
image: app:latest in deployment.yaml

'latest' image tag.
Use explicit semver or digest.
```

---

## Reducing prompt fatigue

### Not every command needs a permission dialog

Each profile ships an approved-commands allowlist — safe, routine operations that bypass the permission prompt entirely, so the guardrails you do see are the ones that matter.

`git status` · `git diff` · `git log` · `git add` · `git commit` · `gh pr create` · `gh pr view` · `bkt pr create` · `bkt repo list` · *+ profile-specific: kubectl, helm, aws, cdk, mvn…*

This list is **customizable** — user settings persist across profile re-installs, so you can extend it as your day-to-day tooling grows.

---

## Nothing happens in the dark

### Every session is visible, every action is logged

Two things run without ever getting in your way: a context banner at session start, and an async audit trail behind every tool call.

`session-start.sh` — injected once, at boot:
```
[Session context]
Host: imac-depot   Environment: unknown   User: govardha
Active rules: dry-run before bulk ops · no prod without staging confirmation first
```

`audit.sh` — one JSONL line per tool call, async, non-blocking:
```json
{"ts":"2026-08-23T17:07Z","user":"govardha","host":"imac-depot","event":"PostToolUse","tool":"Bash","target":"kubectl apply -f deploy.yaml"}
```

---

## Getting started

### One idempotent install, safe to run anytime

The installer hashes every file it manages — unchanged files are skipped, changed ones are backed up with a timestamp before being replaced. Nothing is silently overwritten.

```bash
bash install.sh --dry-run infra-ops   # preview only, no changes
bash install.sh base                  # everyone starts here
bash install.sh sysops                # add a role as your work needs it
```

- **Start with `base`.** Audit, prompt validation, and branch protection — the floor everyone gets.
- **Layer a role profile** when you start touching k8s, AWS CDK, or on-prem ops. Profiles stack — new hooks are added, not swapped.
- **Check `~/.claude/.profile`** to see what's installed and when — useful when onboarding or auditing your own setup.

---

## Takeaways

### Guardrails are what let you move fast here

**Layered, not single-point**
Org sets an unmovable floor. Role hooks add context-aware judgment on top. One layer failing doesn't remove the other.

**Transparent by design**
Every block tells you why and what to do next. Every action — allowed or not — lands in the audit log.

**Scoped to your work**
Six profiles, stackable. You only carry the guards relevant to what you actually touch.

**Low friction by default**
Approved-command allowlists and async audit logging mean the guardrails you notice are the ones worth noticing.

Start with `base`, read `HOOKS.md` when you're curious how something works, and add a role profile the day you need it.
