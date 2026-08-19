# ---------------------------------------------------------------------------
# Remote state backend for the dev environment — intentionally commented out.
#
# The state bucket and DynamoDB lock table are created manually/once by the
# user (see docs/setup/aws-setup.md) — Terraform cannot bootstrap the bucket
# that stores its own state on first apply. Until that bucket exists, this
# environment uses local state (terraform.tfstate here, already covered by
# .gitignore) and `terraform init -backend=false` for validation-only
# workflows (this track's `terraform validate`, CI).
#
# After creating the bucket, uncomment the block below and run:
#   terraform init -migrate-state
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-terraform-state-bucket"
#     key            = "enterprise-cloud-automation/dev/terraform.tfstate"
#     region         = "sa-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
