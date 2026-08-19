variable "name_prefix" {
  description = "Prefix used for naming database resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (needs at least 2, different AZs)."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the RDS instance (typically the db security group from the security module)."
  type        = list(string)
}

variable "engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class. db.t3.micro is AWS free-tier-eligible and the default for this lab-scale project."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GB. Set to 0 to disable storage autoscaling."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name created on the instance."
  type        = string
  default     = "enterprise_automation"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "manage_master_user_password" {
  description = "Let AWS generate and store the master password in Secrets Manager instead of a Terraform-managed plaintext variable (avoids ever writing a password into state or a .tfvars file). Strongly recommended true."
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Enable synchronous Multi-AZ standby failover. Roughly doubles RDS cost. Off by default (dev/staging); recommended on for prod."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "true = terraform destroy leaves no final snapshot (fast/cheap, used in dev/lab so the environment can be torn down freely). Set to false for staging/prod so a snapshot survives destroy — final_snapshot_identifier is then required and generated automatically."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable RDS deletion protection (recommended true for prod)."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Whether to encrypt storage at rest with the default AWS-managed KMS key."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether modifications apply immediately instead of during the next maintenance window. true is convenient for a lab; set false in prod to avoid unplanned downtime."
  type        = bool
  default     = true
}
