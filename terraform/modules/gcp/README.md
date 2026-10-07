# terraform/modules/gcp/

Small, minimal GCP module — a GCS bucket (artifact/state-style storage,
mirroring what `terraform/modules/database`'s S3-equivalent would be) and a
single custom-mode VPC network with one subnet, following the same
`name_prefix` + mandatory-labels convention as the AWS modules
(`terraform/modules/*`).

## Why this exists

The audit item asked for "um pequeno módulo GCP" to demonstrate multi-cloud
Terraform competency, not a second cloud environment. This module:

- Is **not** wired into `terraform/environments/{dev,staging,prod}/` —
  those remain AWS-only (see `terraform/providers.tf`). Adding a real GCP
  environment would need a GCP project, billing account and service
  account key — none of which this portfolio lab provisions (same
  no-real-cloud-cost posture as `terraform apply` for AWS).
- **Has never been `plan`'d or `apply`'d** against a real GCP project in
  this repo (no GCP credentials/project configured here). It is validated
  with `terraform validate` only — see `tests/terraform/test-terraform.sh`,
  which already walks every directory under `terraform/modules/*`
  (this one included) doing `fmt` + `validate`, same as the AWS modules.
- Declares its own `google` provider requirement scoped to this module
  only — it is never instantiated by `terraform/providers.tf` (the AWS
  reference file), so plugging it into a real environment later is a
  deliberate, explicit choice (add a `provider "google" {}` block and a
  `module "gcp" { source = "../../modules/gcp" ... }` call), not an
  accident of a shared provider block.

## Resources

- `google_storage_bucket.this` — versioned, uniform-bucket-level-access
  GCS bucket with a lifecycle rule (abort incomplete multipart uploads),
  mirroring the "artifacts" bucket pattern already used for AWS S3
  elsewhere in this project (see `database/README.md`'s mention of
  `caterpillar-automation-artifacts` in the dashboard demo data).
- `google_compute_network.this` — custom-mode VPC (no default subnets).
- `google_compute_subnetwork.this` — one subnet, with private Google
  access enabled and flow logs on (parallels the AWS networking module's
  VPC flow-log-friendly posture).

## Tagging / labels convention

GCP has no native tag-value-as-string-list concept like AWS `default_tags`
— labels are a flat `map(string)` applied per-resource. This module merges
`var.labels` (the GCP equivalent of the AWS modules' `var.tags`) onto every
labelable resource, using the **same mandatory keys**
(`environment`, `project`, `managed_by`, `owner`, `cost_center` — lowercase,
per GCP label key constraints) that `terraform/providers.tf`'s
`default_tags` applies on the AWS side, so the OPA tag-propagation policy
(`policies/opa/terraform_tags.rego`) and its test
(`tests/terraform/test_tag_propagation.py`) cover this module the same way
they cover every AWS module.
