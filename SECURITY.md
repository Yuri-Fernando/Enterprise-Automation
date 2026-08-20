# Security Policy

This is a personal portfolio project (**Enterprise Cloud Automation &
Infrastructure Platform**, by Yuri Fernando Dubbern). It is **not** software
built or endorsed by Caterpillar, and it does not represent a production
system with real users or real data. That said, it follows real
infrastructure-security practices deliberately, because demonstrating those
practices is the point of the project. See [`escopo.md`](escopo.md) and
[`docs/architecture.md`](docs/architecture.md) for context.

## Reporting a vulnerability or concern

If you find a security issue in this repository (e.g. an accidentally
committed credential, an overly permissive IAM policy that slipped past CI,
or a misconfigured public resource):

1. **Do not open a public GitHub issue for a live credential leak.**
2. Contact the maintainer directly: yuri.dubbern@gmail.com.
3. Include the affected file/path, a description of the issue, and — if
   applicable — the commit hash where it was introduced.

Since this is a solo portfolio project (not a maintained product with an
SLA), there's no formal disclosure timeline, but reports will be reviewed
and acted on promptly, and credentials will be rotated/revoked immediately
if a leak is confirmed.

## How secrets are managed

- **Never in Git.** No AWS access keys, `.tfvars` with real values,
  database passwords, or API tokens are committed. `.gitignore` excludes
  `*.tfvars` (except `*.tfvars.example`), `.env` files, and local state.
- **CI/CD secrets** (when configured) live in **GitHub Actions Secrets**
  (repository or environment scoped) — see
  [`docs/setup/github-setup.md`](docs/setup/github-setup.md). The
  preferred pattern is **AWS OIDC federation** (`AWS_ROLE_TO_ASSUME`
  secret + `aws-actions/configure-aws-credentials`), which avoids
  long-lived AWS access keys entirely. Static access keys are a documented
  fallback only.
- **Runtime secrets on AWS** (DB credentials, API keys used by the
  automation controller) are intended to be stored in **AWS Secrets
  Manager** or **SSM Parameter Store**, never in Terraform variables
  committed to the repo or in plaintext environment files.
- **Local development** uses `.env` / `*.tfvars` files that are
  git-ignored; `*.example` templates are committed instead so the shape is
  documented without exposing real values.

## IAM and least privilege

- No module should define `Action: "*"` / `Resource: "*"` IAM policies.
  This is enforced in CI by `checkov` (see
  [`.github/workflows/security-scan.yml`](.github/workflows/security-scan.yml)
  and [`.checkov.yaml`](.checkov.yaml)), which hard-fails the pipeline on
  HIGH/CRITICAL findings — permissive IAM policies are flagged at that
  severity by default.
- The IAM role/user used by CI (for `terraform plan`, and eventually
  `apply`) should be scoped to only what the pipeline needs, ideally via a
  short-lived OIDC-federated role rather than a long-lived IAM user.
- See [`docs/setup/aws-setup.md`](docs/setup/aws-setup.md) for the
  pre-`apply` security checklist (MFA, least-privilege role setup, etc.).

## Scope of automated scanning

- **Terraform**: `terraform fmt`, `terraform validate`, `tflint`, and
  `checkov` run on every PR that touches `terraform/**` (see
  [`.github/workflows/terraform-ci.yml`](.github/workflows/terraform-ci.yml)
  and
  [`.github/workflows/security-scan.yml`](.github/workflows/security-scan.yml)).
- **Ansible**: `ansible-lint` on every PR touching `ansible/**`.
- **Python**: `pytest` (with coverage) on every PR touching
  `automation/**` or `tests/**`.
- **PowerShell**: `Pester` + `PSScriptAnalyzer` on every PR touching
  `powershell/**`.

None of these pipelines run `terraform apply` automatically — applying
infrastructure changes is always a deliberate, manual action taken by the
project owner after reviewing a plan.
