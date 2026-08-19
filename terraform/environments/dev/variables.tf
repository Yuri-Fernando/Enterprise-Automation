# ---------------------------------------------------------------------------
# dev environment variables — minimum footprint on purpose (single AZ pair,
# t3.micro, no NAT Gateway, no Multi-AZ RDS, no deletion protection). See
# terraform.tfvars.example for the values actually recommended for dev.
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
  default     = "dev"
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
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, same order as var.azs)."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ, same order as var.azs)."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private-subnet instances get outbound internet access. Off by default in dev — instances launch in public subnets instead (see instance_subnet_ids wiring in main.tf)."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "When enable_nat_gateway = true: one shared NAT Gateway (cheaper) vs one per AZ (higher availability). Single is fine for dev."
  type        = bool
  default     = true
}

# --- Security ------------------------------------------------------------

variable "web_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_access_cidrs" {
  description = "CIDR blocks allowed direct SSH/RDP to app instances. Empty by default — access via SSM Session Manager only."
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
  description = "EC2 instance type for the Auto Scaling Group. t3.micro is free-tier-eligible — kept small in dev on purpose."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH/RDP access. Leave null to rely on SSM Session Manager only."
  type        = string
  default     = null
}

variable "app_port" {
  description = "Port the application/instances listen on."
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Auto Scaling Group minimum size. Single instance in dev — no redundancy needed for a lab environment."
  type        = number
  default     = 1
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS (443) ALB listener. Requires certificate_arn."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
  default     = ""
}

variable "enable_alb_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB. Off in dev so the environment can be torn down freely."
  type        = bool
  default     = false
}

# --- Database --------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class. db.t3.micro is free-tier-eligible."
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ RDS failover. Off in dev — doubles RDS cost and isn't needed for a lab environment."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "true = terraform destroy leaves no final snapshot (fast/cheap — appropriate for dev)."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Whether to enable RDS deletion protection. Off in dev so the environment can be torn down freely."
  type        = bool
  default     = false
}

# --- Monitoring --------------------------------------------------------------

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for CloudWatch alarm notifications."
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address subscribed to the alarm SNS topic when create_sns_topic = true. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "enable_ec2_alarms" {
  description = "Whether to create CPU/status-check alarms for the Auto Scaling Group."
  type        = bool
  default     = true
}

variable "enable_alb_alarms" {
  description = "Whether to create ALB 5xx/unhealthy-host alarms."
  type        = bool
  default     = true
}

variable "enable_rds_alarms" {
  description = "Whether to create RDS CPU/free-storage alarms."
  type        = bool
  default     = true
}

# --- IAM / GitHub Actions OIDC ----------------------------------------------

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider. AWS allows only one per account — set false (and pass existing_github_oidc_provider_arn) in whichever environment applies second."
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
  default     = "Yuri-Fernando"
}

variable "github_repo" {
  description = "GitHub repository name allowed to assume the GitHub Actions role."
  type        = string
  default     = "Caterpillar-Enterprise-Cloud-Automation"
}

variable "github_allowed_branches" {
  description = "Git refs allowed to assume the GitHub Actions role via OIDC."
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform remote state, granted to the GitHub Actions role. Leave empty until the bucket exists (see backend.tf)."
  type        = string
  default     = ""
}

variable "state_lock_table_arn" {
  description = "ARN of the DynamoDB table used for Terraform state locking, granted to the GitHub Actions role."
  type        = string
  default     = ""
}
