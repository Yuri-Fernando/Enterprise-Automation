# ---------------------------------------------------------------------------
# REFERENCE FILE — backend example, intentionally NOT active.
#
# This repository does not create or manage its own Terraform state bucket
# (that would be a chicken-and-egg problem: the bucket that stores state
# can't itself be tracked in that same state on first apply). The bucket and
# DynamoDB lock table are created manually/once by the user — see the
# step-by-step in `docs/setup/aws-setup.md`.
#
# Each environment under `environments/<env>/` has its own `backend.tf` with
# this same commented-out block, differing only in the `key` (state file
# path within the bucket) so dev/staging/prod never collide.
#
# Until you create the bucket and uncomment the block, every environment
# uses local state (`terraform.tfstate` in the environment directory — already
# covered by `.gitignore`, never commit it) and `terraform init -backend=false`
# for validation-only workflows (CI, `terraform validate`).
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-ME-terraform-state-bucket"
#     key            = "enterprise-cloud-automation/<env>/terraform.tfstate"
#     region         = "sa-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
#
# Bootstrap commands (run once, manually, before the first real `apply`):
#
#   aws s3api create-bucket --bucket <seu-bucket-tfstate> --region sa-east-1 \
#     --create-bucket-configuration LocationConstraint=sa-east-1
#   aws s3api put-bucket-versioning --bucket <seu-bucket-tfstate> \
#     --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket <seu-bucket-tfstate> \
#     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#   aws dynamodb create-table --table-name terraform-locks \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST --region sa-east-1
#
# After creating the bucket, uncomment the block in
# environments/<env>/backend.tf and run:
#
#   terraform init -migrate-state
