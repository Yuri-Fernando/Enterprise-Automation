# TFLint configuration — Enterprise Cloud Automation & Infrastructure
# Platform.
#
# Used by .github/workflows/terraform-ci.yml (`tflint` job) against each
# environment under terraform/environments/*. Run locally (optional) from
# the repo root with:
#   tflint --init
#   tflint --recursive

plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  format  = "compact"
  module  = true
  force   = false
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = false
}

rule "terraform_documented_variables" {
  enabled = false
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# AWS-specific: catches overly permissive IAM policies, unencrypted
# resources, etc. (complements checkov, which is the primary security gate
# — see .checkov.yaml and .github/workflows/security-scan.yml).
rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = false
}
