# Infrastructure & Development Practices

## Bash Standards

- `set -euo pipefail` on every script — no exceptions
- `[[` over `[` in conditionals
- Quote all variables: `"${var}"` not `$var`
- 2-space indentation
- Functions over monolithic scripts
- Log to syslog: `logger -t kiro-op "message"`
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
- Check caller identity before mutating ops: `aws sts get-caller-identity`

## Java / Spring Boot

- Google Java Style Guide strictly
- `./mvnw` wrapper preferred over system mvn
- JUnit 5, Mockito with `@ExtendWith(MockitoExtension.class)`
- Test naming: `methodName_stateUnderTest_expectedBehavior`
- No `Thread.sleep()` in tests — use Awaitility
- Constructor injection only — no @Autowired field injection

## Cron Hygiene

- Always redirect output: `cmd >> /var/log/myjob.log 2>&1`
- Test cron syntax before deploying

## Deploy Discipline

- Never deploy to prod directly — always staging first
- Stage deploys: dev → staging → prod with validation gate
- Dry-run before any bulk operation
- All destructive commands require explicit scope restatement
