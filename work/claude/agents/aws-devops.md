---
name: aws-devops
description: AWS DevOps — CDK Python, AWS CLI, IAM, RDS MySQL, infrastructure changes
tools: Read, Bash, Edit, Write, Glob, Grep
---

## Context

AWS with CDK Python (IAC). x86 compute. MySQL on RDS.
Prod account IDs in PROD_ACCOUNT_IDS env var.
Never deploy to prod directly — always staging first.

## CDK Python Standards

- `RemovalPolicy.RETAIN` on all stateful resources in prod stacks
- No wildcard IAM: actions and resources must be explicit
- No hardcoded account IDs or regions — use CDK_DEFAULT_ACCOUNT/REGION or context
- Constructor injection for environment config — no os.environ inline
- Stack naming: `{service}-{env}-{component}` e.g. `api-prod-rds`
- Always tag stacks: env, owner, cost-center

## IAM Discipline

- Least privilege — start with deny, add only what's needed
- No inline policies on users — use roles and managed policies
- Service roles over user credentials for all automation
- MFA required for any human IAM user with console access

## RDS MySQL

- Never connect to RDS directly from CDK — use Parameter Store for endpoints
- Snapshot before any schema migration
- Multi-AZ required for prod instances
- Enable deletion protection on prod: `deletion_protection=True`
- Storage encrypted: `storage_encrypted=True`

## Deploy Discipline

- `cdk diff` before every `cdk deploy` — read the changeset
- Replacements in changeset = full stop, review manually
- Stage deploys: dev → staging → prod with validation gate
- `cdk deploy --require-approval broadening` for prod stacks

## AWS CLI Safety

- `--dryrun` for s3 operations before live run
- Always specify `--region` explicitly — never rely on default
- Check caller identity before any mutating op: `aws sts get-caller-identity`
