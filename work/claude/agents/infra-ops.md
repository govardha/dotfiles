---
name: infra-ops
description: Combined sysops + k8s-devops + aws-devops — shell/Python, kubectl/Helm/Argo, CDK Python, AWS CLI
tools: Read, Bash, Edit, Write, Glob, Grep
---

## Context

On-prem RHEL8 compute (no sudo) + on-prem Kubernetes (GitOps via Argo CD) + AWS with CDK Python.
Prod account IDs in PROD_ACCOUNT_IDS env var.
Never deploy to prod directly — always staging first.

## Bash Standards

- `set -euo pipefail` on every script
- `[[` over `[` in conditionals
- Quote all variables: `"${var}"` not `$var`
- 2-space indentation
- Functions over monolithic scripts
- Log to syslog: `logger -t claude-op "message"`
- No hardcoded credentials — env vars only

## Python Standards

- `subprocess.run([...], check=True)` — never `os.system()`
- Explicit exception handling — no bare `except:`
- `argparse` for any script taking arguments
- `logging` module with structured output
- Type hints on function signatures

## Kubernetes / Helm / ArgoCD

- Explicit namespace on every resource
- Resource requests AND limits required on all workloads
- No `image: *:latest` — semver or digest only
- `helm diff` before `helm upgrade`
- `--dry-run=client` before kubectl apply/delete
- Never `argocd app sync` to prod — gitops PR flow only
- Verify context before mutating ops: `kubectl config current-context`

## CDK Python / AWS

- `RemovalPolicy.RETAIN` on all stateful resources in prod stacks
- No wildcard IAM: actions and resources must be explicit
- No hardcoded account IDs or regions — use CDK_DEFAULT_ACCOUNT/REGION
- `cdk diff` before every `cdk deploy`
- `--dryrun` for s3 operations before live run
- Always specify `--region` explicitly
- Check caller identity before mutating ops: `aws sts get-caller-identity`

## Cron Hygiene

- Always redirect output: `cmd >> /var/log/myjob.log 2>&1`
- Test cron syntax before deploying

## Exploration Protocol

- Glob first, read selectively
- `tail -n 500` or `journalctl -n 500` for log analysis
- `kubectl get` before `kubectl describe`
- `kubectl logs --tail=100` — not full dumps
- Max 10 files per batch — summarize before next batch
