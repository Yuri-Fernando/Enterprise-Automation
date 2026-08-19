# ---------------------------------------------------------------------------
# REFERENCE FILE — not a Terraform root module by itself.
#
# Mirrors the common variable set that every `environments/<env>/variables.tf`
# declares. Kept here as a single place to see the naming/typing convention
# without diffing dev/staging/prod. Each environment sets its own defaults
# (e.g. `environment = "prod"`, different `min_size`/`max_size`, etc.) — see
# `environments/<env>/terraform.tfvars.example` for the values actually
# recommended per environment.
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
  description = "Environment name (dev | staging | prod). Also used as the mandatory 'Environment' tag."
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
  description = "Create a NAT Gateway so private-subnet instances get outbound internet access. Defaults to false — NAT Gateway bills ~$0.045/hour plus data processing even when idle, and this lab does not need outbound internet from private subnets by default (instances launch in public subnets instead when this is false, see environments/<env>/main.tf)."
  type        = bool
  default     = false
}

# --- Compute -------------------------------------------------------------

variable "os_type" {
  description = "\"linux\" or \"windows\" — selects the AMI family and user_data used by the compute module."
  type        = string
  default     = "linux"
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group. t3.micro is the AWS free-tier-eligible default."
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

# --- Database --------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class. db.t3.micro is the AWS free-tier-eligible default."
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ RDS failover. Doubles RDS cost — off by default, on by default in prod."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "true = terraform destroy leaves no final snapshot (fast/cheap — used in dev/lab). Set false in staging/prod so a snapshot survives destroy."
  type        = bool
  default     = true
}
