# ---------------------------------------------------------------------------
# prod environment variables — highest redundancy tier of the three, but
# every redundancy knob (NAT Gateway, Multi-AZ RDS, deletion protection,
# per-AZ NAT) still defaults to false/off here, exactly like dev/staging.
# No environment forces AWS cost just by running `terraform apply` with
# defaults — a real prod rollout opts in explicitly via terraform.tfvars
# (see terraform.tfvars.example, which documents the recommended prod
# values and the cost each one adds).
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region used by this environment."
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Short, stable project identifier used to name and tag every resource."
  type        = string
  default     = "enterprise-cloud-automation"
}

variable "environment" {
  description = "Environment name. Also used as the mandatory 'Environment' tag."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag value — who is responsible for this environment's resources."
  type        = string
  default     = "yuri-dubbern"
}

variable "cost_center" {
  description = "CostCenter tag value — used to attribute AWS billing in cost reports."
  type        = string
  default     = "portfolio-lab"
}

# --- Networking --------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.2.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across. A real prod rollout should use 3 for extra resilience — add a third here and matching CIDRs if desired."
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, same order as var.azs)."
  type        = list(string)
  default     = ["10.2.0.0/24", "10.2.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ, same order as var.azs)."
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private-subnet instances get outbound internet access. Off by default even in prod to avoid forced cost — a real prod rollout sets this true (see terraform.tfvars.example)."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "When enable_nat_gateway = true: one shared NAT Gateway (cheaper, single point of failure) vs one per AZ (higher availability, recommended for real prod)."
  type        = bool
  default     = false
}

# --- Security ------------------------------------------------------------

variable "web_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_access_cidrs" {
  description = "CIDR blocks allowed direct SSH/RDP to app instances. Empty by default — access via SSM Session Manager only, strongly recommended for prod."
  type        = list(string)
  default     = []
}

# --- Compute -------------------------------------------------------------

variable "os_type" {
  description = "\"linux\" or \"windows\" — selects the AMI family and user_data used by the compute module."
  type        = string
  default     = "linux"
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 key pair name for SSH/RDP access. Leave null to rely on SSM Session Manager only (recommended for prod)."
  type        = string
  default     = null
}

variable "app_port" {
  description = "Port the application/instances listen on."
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Auto Scaling Group minimum size. Kept at 1 by default for cost — set >= 2 in terraform.tfvars for real prod redundancy across AZs."
  type        = number
  default     = 1
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS (443) ALB listener. Requires certificate_arn — strongly recommended for real prod traffic."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
  default     = ""
}

variable "enable_alb_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB. Off by default; recommended true once real prod traffic depends on this ALB."
  type        = bool
  default     = false
}

# --- Database --------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ RDS synchronous failover. Off by default (doubles RDS cost) — this is the main knob a real prod rollout should turn on."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "true = terraform destroy leaves no final snapshot. Recommended false for prod so a snapshot always survives a destroy."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Whether to enable RDS deletion protection. Off by default; strongly recommended true for real prod data."
  type        = bool
  default     = false
}

# --- Monitoring --------------------------------------------------------------

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for CloudWatch alarm notifications. Recommended true for prod so alarms actually page someone."
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address subscribed to the alarm SNS topic when create_sns_topic = true."
  type        = string
  default     = ""
}

variable "enable_ec2_alarms" {
  type    = bool
  default = true
}

variable "enable_alb_alarms" {
  type    = bool
  default = true
}

variable "enable_rds_alarms" {
  type    = bool
  default = true
}

# --- IAM / GitHub Actions OIDC ----------------------------------------------

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider. AWS allows only one per account — dev owns creation by convention here, prod reuses it via existing_github_oidc_provider_arn."
  type        = bool
  default     = false
}

variable "existing_github_oidc_provider_arn" {
  description = "ARN of an already-existing GitHub OIDC provider (created by the dev environment by convention here)."
  type        = string
  default     = ""
}

variable "github_org" {
  type    = string
  default = "Yuri-Fernando"
}

variable "github_repo" {
  type    = string
  default = "Caterpillar-Enterprise-Cloud-Automation"
}

variable "github_allowed_branches" {
  type    = list(string)
  default = ["ref:refs/heads/main"]
}

variable "state_bucket_arn" {
  type    = string
  default = ""
}

variable "state_lock_table_arn" {
  type    = string
  default = ""
}
