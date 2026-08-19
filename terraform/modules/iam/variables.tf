variable "name_prefix" {
  description = "Prefix used for naming all IAM resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "create_ec2_role" {
  description = "Whether to create the EC2 instance role/profile."
  type        = bool
  default     = true
}

variable "ec2_managed_policy_arns" {
  description = "Extra AWS managed policy ARNs attached to the EC2 role in addition to the least-privilege inline CloudWatch policy this module creates. Defaults to AmazonSSMManagedInstanceCore so instances can be reached via SSM Session Manager instead of opening SSH/RDP."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider (token.actions.githubusercontent.com). AWS allows only one OIDC provider per URL per account — if it already exists (e.g. created by another environment's apply), set this to false and pass its ARN via existing_github_oidc_provider_arn."
  type        = bool
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  description = "ARN of an already-existing GitHub OIDC provider. Only used when create_github_oidc_provider = false."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository allowed to assume the GitHub Actions role."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name allowed to assume the GitHub Actions role."
  type        = string
}

variable "github_allowed_branches" {
  description = "Git refs allowed to assume the GitHub Actions role via OIDC, e.g. [\"ref:refs/heads/main\"]. Use [\"*\"] to allow any ref (not recommended)."
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform remote state, granted read/write to the GitHub Actions role. Leave empty to skip (role is still created, just without state permissions)."
  type        = string
  default     = ""
}

variable "state_lock_table_arn" {
  description = "ARN of the DynamoDB table used for Terraform state locking, granted to the GitHub Actions role."
  type        = string
  default     = ""
}
