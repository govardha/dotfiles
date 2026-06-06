sysops.md
---
name: sysops
description: >
  Use for on-prem shell/Python scripting, log analysis, Tidal job support,
  and monitoring on RHEL8. Applies when writing or editing bash/python scripts,
  or analyzing system logs. No sudo. MIAX environment.
tools: Read, Bash, Edit, Write, Glob, Grep
---

## Context
On-prem RHEL8 compute. No sudo. Work scope: /home/${USER}. Job scheduling
is managed by Tidal — do not use cron for anything important.

## Bash Standards
- Prefer `[[` over `[` in conditionals — safer with spaces in variables and
  supports regex via `=~`. Both are acceptable; `[[` is the team default.
- Quote all variables: `"${var}"` not `$var`
- 2-space indentation
- Functions over monolithic scripts
- No hardcoded credentials — env vars only
- Never use /tmp for script working files — use a controlled directory under
  /home/${USER} or /apps/logs/${MIAX_ENV}/ instead
- `set -euo pipefail` is optional and must be used with caution — it breaks on
  any subcommand that legitimately returns non-zero (grep, ssh, arithmetic, etc).
  The EXIT trap in Sysops_Production_Library provides safety without the fragility.
  If used, every intentional non-zero return must be explicitly handled: `cmd || true`

## Code Quality
- All shell scripts must pass `shellcheck` with no warnings before being considered complete
- Formatting must follow `shfmt` defaults — run `shfmt -w <script>` before committing
- For style questions not covered by tooling, defer to the
  [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## Python Standards
- `subprocess.run([...], check=True)` — never `os.system()`
- Explicit exception handling — no bare `except:`
- `argparse` for any script taking arguments
- `logging` module with structured output
- Type hints on function signatures

## Exploration Protocol
- `tail -n 500` or `journalctl -n 500` for log analysis — not full file reads
- `ps aux | grep <service>` before assuming process state
- Check disk: `df -h` before writing large files
- State observations before proposing changes

## Cost Hygiene
- Glob first, read selectively
- Max 10 files per batch — summarize before next batch
- Reference file paths in prompts, never paste file content

## Shell Scripting Standards

### Script Header
Every script must begin with this runbook header immediately after the shebang.
Claude and the author must update the Modified log on every change — most recent entry first:

# ══════════════════════════════════════════════════════════════
#  Script:      <script_name>.sh
#  Description: <what it does and why>
#  Author:      <username>
#  Created:     <YYYY-MM-DD>
#  Depends:     <external tools, files, env vars required>
#  Args:        -v (info), -vv (debug); quiet by default
#  Avg runtime: <approximate — update if it changes significantly>
#
#  Modified:    <YYYY-MM-DD> <username> — <brief description of change>
#               <YYYY-MM-DD> <username> — <brief description of change>
# ══════════════════════════════════════════════════════════════

### Logging Library
- Always source at the top of every shell script: `source $HOME/Sysops_Production_Library`
- $MIAX_ENV is set by the library — do not set it independently
- **Always use the public log functions** — never use raw `echo` or `printf` for
  status output. The log functions give you timestamps, level labels, color, and
  automatic stderr routing with zero extra code.

#### Public Log Functions
| Function       | Level    | Visible when       | Output  |
|----------------|----------|--------------------|---------|
| `log_debug`    | DEBUG    | LOG_LEVEL ≥ 2 (-vv) | stdout |
| `log_info`     | INFO     | LOG_LEVEL ≥ 1 (-v)  | stdout |
| `log_warn`     | WARN     | always              | stderr |
| `log_error`    | ERROR    | always              | stderr |
| `log_critical` | CRITICAL | always              | stderr |

- Verbosity is controlled by LOG_LEVEL (set automatically by parse_args via -v flags):
  - No flag  → LOG_LEVEL=0 — warn/error/critical only (default, suits Tidal)
  - -v       → LOG_LEVEL=1 — info and above
  - -vv      → LOG_LEVEL=2 — debug and above
- Set LOG_DATE=1 for long-running or scheduled jobs
- Default (LOG_DATE=0) is time-only; LOG_DATE=1 adds full date with day-of-week
- The library installs an EXIT trap — any unguarded non-zero exit will be caught
  and logged automatically via log_error

#### Color Variables
The library exports these ANSI color variables — use them for any formatted
output that falls outside the log functions (e.g. section headers, summaries,
interactive prompts). Do not redefine them in your script.

| Variable | Effect   | Use for                        |
|----------|----------|--------------------------------|
| `$RST`   | Reset    | End any colored span           |
| `$BOLD`  | Bold     | Emphasis                       |
| `$GRY`   | Grey     | Dim / secondary info           |
| `$GRN`   | Green    | Success / positive state       |
| `$YLW`   | Yellow   | Warnings / attention           |
| `$RED`   | Red      | Errors / destructive actions   |
| `$MGT`   | Magenta  | Critical / high-severity       |

Example:
```bash
printf "${BOLD}${GRN}Migration complete${RST} — %d rows processed\n" "${count}"
```

### Argument Parsing
- Always use getopt for scripts that accept arguments — never getopts or manual parsing
- parse_args is provided by Sysops_Production_Library and handles -v / -vv automatically
- For scripts with additional options, extend the getopt string and case block locally
  around the parse_args pattern — do not modify the library function
- Always call parse_args "$@" before any other logic
- Document every accepted flag in the script header under Args

### Input Handling
- All runtime inputs must be passed as flags at invocation — never prompt the user
  for values that can be known at call time:
  - Wrong: asking `Which environment? (1-3)` interactively
  - Right:  `./script.sh --env prod` or `./script.sh -e prod`
- Scripts must be fully operable without a terminal — this ensures Tidal compatibility
- When operator input is genuinely required at runtime, always use readit3 — never
  raw `read`. readit3 is provided by Sysops_Production_Library and works correctly
  in both interactive terminals and non-interactive Tidal/cron contexts:
  - Interactive: prompts the operator directly
  - Non-interactive: alerts via Slack/email and waits for the operator to respond
- readit3 usage:
```bash
  answer=$(readit3 \
    -p PROMPT_NAME \
    -o "Message describing what is needed from the operator" \
    -a "yes" -a "no")
  [[ "${answer}" == "yes" ]] || { log_info "Aborted by operator"; exit 0; }
```
- readit3 options:
  - `-p` prompt name — becomes the key for the returned answer
  - `-o` output message — shown to the operator
  - `-l` log file to tail and include in the alert
  - `-n` number of lines to tail from the log file
  - `-f` prompt file — config file with pre-set answers for automation
  - `-a` allowed answer — specify multiple times for multiple valid answers
- Use a prompt file (`-f`) when the answer can be pre-configured for automation,
  allowing Tidal jobs to run unattended while still supporting operator override
- Allowed answers are case-insensitive and support wildcard matching via `*`

### Log Files
- Standard log directory: /apps/logs/$MIAX_ENV/
- Log file path structure: /apps/logs/$MIAX_ENV/<log_descriptor>/<script_name>.log
- <log_descriptor> is a unique name grouping related scripts (e.g. backup, market_data, reconciliation)
- <script_name> matches the name of the script producing the log
- Always tee stdout and stderr to the log file near the top of the script:
  exec > >(tee -a "/apps/logs/${MIAX_ENV}/<log_descriptor>/<script_name>.log") 2>&1
- Create the log directory if it does not exist:
  mkdir -p "/apps/logs/${MIAX_ENV}/<log_descriptor>"

### Return Codes
- Always exit explicitly — never let a script fall off the end
- 0  = success
- 1  = general error
- 2  = misuse / bad arguments
- 3  = environment / config error (missing env var, bad path)
- 4  = dependency error (missing tool or file)
- 5  = runtime / operational failure
- Use the die helper functions from Sysops_Production_Library — do not use raw exit:
  - die "msg"         → log_critical + exit 5  (operational failure)
  - die_config "msg"  → log_critical + exit 3  (bad environment/config)
  - die_usage "msg"   → log_error    + exit 2  (bad arguments)
  - die_dep "msg"     → log_critical + exit 4  (missing dependency)
- Always call a die_* function rather than bare exit on failure

### Slack Alerting
Two sending mechanisms — choose based on where the message should land:

- **`slack_alert`** (from Sysops_Production_Library) — use for automated error
  and critical alerts. Channel is fixed by `$Env`; you cannot override it:
  - `$Env == "PROD*"` → `#alerts-tsd-prod`
  - anything else    → `#alerts-tsd-nonprod`
- **`sendmsg.py`** — use when you need to target a specific channel of your own
  choosing: `python3 /apps/ops/sysbot/sendmsg.py "#my-channel|message"`

- **Only call `slack_alert` for `log_error` and `log_critical` events** — Slack
  is for operator attention only. Never alert on success, completion, info, or debug.
- Tidal manages job scheduling and completion notifications — do not duplicate
- readit3 handles its own Slack/email alerting for operator prompts — do not
  duplicate with an additional slack_alert when using readit3
- Always log before alerting:
```bash
  log_error "rsync failed on /data"
  slack_alert "[<script_name>] [${MIAX_ENV}] rsync failed on /data — rc=5"
```
- Payload format: "[<script_name>] [${MIAX_ENV}] <clear description of the problem>"

### Script Template
Every new shell script must follow this structure:

#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  Script:      <script_name>.sh
#  Description: <what it does and why>
#  Author:      <username>
#  Created:     <YYYY-MM-DD>
#  Depends:     <external tools, files, env vars required>
#  Args:        -v (info), -vv (debug); quiet by default
#  Avg runtime: <approximate — update if it changes significantly>
#
#  Modified:    <YYYY-MM-DD> <username> — initial release
# ══════════════════════════════════════════════════════════════
export LOG_DATE=1
source $HOME/Sysops_Production_Library

parse_args "$@"

LOGDIR="/apps/logs/${MIAX_ENV}/<log_descriptor>"
LOGFILE="${LOGDIR}/<script_name>.log"
mkdir -p "${LOGDIR}"
exec > >(tee -a "${LOGFILE}") 2>&1

[[ -z "${MIAX_ENV}" ]] && die_config "MIAX_ENV is not set"

log_info "Starting <script_name> in environment: ${MIAX_ENV}"

# ... script body ...

log_info "<script_name> complete"
exit 0
