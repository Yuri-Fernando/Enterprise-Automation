# ---------------------------------------------------------------------------
# REFERENCE FILE — not a Terraform root module by itself.
#
# Terraform does not share state or configuration between independent root
# directories, so each environment under `environments/<env>/` has its own
# complete copy of `providers.tf` (and `variables.tf`, `backend.tf`). This
# file documents the convention every environment follows, so a reviewer
# only needs to read it once instead of diffing three near-identical files.
#
# Convention:
#   - `required_version` pins the minimum Terraform CLI version tested by
#     this project (see `docs/logs/terraform.md` for the exact version used
#     in validation).
#   - `required_providers` pins the AWS provider to a minor version range
#     (`~> 5.0`) so `terraform init` never silently jumps to a breaking
#     major version.
#   - `default_tags` on the `aws` provider block is how the mandatory tags
#     (`Environment`, `Project`, `ManagedBy`, `Owner`, `CostCenter`) are
#     applied to every resource automatically, without repeating a `tags`
#     block on each resource. Module-level resources can still `merge()`
#     extra tags (e.g. `Name`) on top of these.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}
