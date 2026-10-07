variable "name_prefix" {
  description = "Prefix used for naming every resource created by this module."
  type        = string
}

variable "project_id" {
  description = "GCP project ID that owns these resources. Never defaulted — must be explicit so this module can't accidentally target the wrong project if it's ever wired into a real environment."
  type        = string
}

variable "region" {
  description = "GCP region for the bucket and subnetwork."
  type        = string
  default     = "southamerica-east1" # São Paulo — same geography as the AWS sa-east-1 default.
}

variable "labels" {
  description = "Labels merged onto every labelable resource. GCP requires lowercase keys/values — mirrors the mandatory AWS tag set (Environment/Project/ManagedBy/Owner/CostCenter in terraform/providers.tf) but lowercased: environment, project, managed_by, owner, cost_center."
  type        = map(string)
  default     = {}
}

# --- Storage -----------------------------------------------------------

variable "bucket_force_destroy" {
  description = "Allow Terraform to delete the bucket even if it still contains objects. Keep false outside of throwaway/demo use."
  type        = bool
  default     = false
}

variable "bucket_versioning_enabled" {
  description = "Enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "bucket_storage_class" {
  description = "Default storage class for the bucket."
  type        = string
  default     = "STANDARD"
}

# --- Networking ----------------------------------------------------------

variable "subnet_cidr" {
  description = "CIDR range for the single subnet created in the custom-mode VPC."
  type        = string
  default     = "10.20.0.0/24"
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs on the subnet (mirrors the AWS networking module's observability posture)."
  type        = bool
  default     = true
}
