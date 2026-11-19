# minibank-infra

Terraform for minibank. Project-wide rules, status and workflow:

@../minibank/CLAUDE.md

Design: `../minibank/docs/superpowers/specs/2026-10-26-minibank-infra-design.md` (§9.1 layout, §10 CI).

## Layout

- Each leaf folder is one root module with its **own state**. State key = folder path.
- `bootstrap/` — state buckets (run by hand once). `management/` — Organizations, budget, SCP.
- `workload/dev/persistent/` — lives forever (network, data, identity, dns, ci-oidc, ...).
- `workload/dev/ephemeral/` — `up` / `down` only (NAT, EKS, add-ons). **Ephemeral reads
  persistent outputs, never the other way.** `down` must not touch persistent resources.
- `modules/` — small own modules only when `terraform-aws-modules/*` does not fit.

## New stack checklist

1. Copy `backend.tf` + `providers.tf` from a sibling; set the state key to the folder path.
2. Workload stacks: bucket `minibank-tfstate-701254204984`, `use_lockfile = true`, no DynamoDB.
3. Provider: `allowed_account_ids`, region `ap-southeast-1`, `default_tags` with
   `Project`, `ManagedBy`, `Stack`, plus `env=dev` and `component=<folder>` (spec §9.1).
4. Pin versions: Terraform from `.terraform-version`, AWS provider `~> 6.0`, modules exact.
5. Resources built in the console: add an `import` block; match console defaults (comment,
   tags, names) so the plan is clean.
6. Anything whose loss breaks things (zone, KMS, Aurora, state): `prevent_destroy = true`.
7. Add the folder to the matrix in `.github/workflows/terraform-pr.yml`.
8. Commit `.terraform.lock.hcl`. Never commit `*.tfstate` or real `*.tfvars`.

## Checks Claude may run

```bash
terraform fmt -check -recursive        # repo root
terraform init -backend=false && terraform validate
AWS_PROFILE=minibank-workload terraform plan -lock=false   # read-only
```

Never run `apply`, `destroy`, `import` (CLI) or `state rm/mv` — give the commands to the user.

## Gotchas

- GitHub OIDC here uses **immutable subjects**: `repo:ducnghiaaa@129480468/minibank-infra@1459049748:<context>`.
  Trust policies must use this form.
- A CI plan that ran before the user's local apply shows old results; re-run it.
