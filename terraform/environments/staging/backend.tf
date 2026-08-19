# ---------------------------------------------------------------------------
# Remote state backend for the staging environment — intentionally commented
# out. See environments/dev/backend.tf for the full rationale; only the
# state `key` differs per environment so dev/staging/prod never collide.
#
# Until the bucket exists, this environment uses local state and
# `terraform init -backend=false` for validation-only workflows.
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-terraform-state-bucket"
#     key            = "enterprise-cloud-automation/staging/terraform.tfstate"
#     region         = "sa-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
