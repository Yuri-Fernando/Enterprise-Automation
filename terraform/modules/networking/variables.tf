variable "name_prefix" {
  description = "Prefix used for naming all networking resources (e.g. \"enterprise-cloud-automation-dev\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across. Needs at least 2 entries for the ALB and RDS subnet group to be valid."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least 2 availability zones are required (ALB and RDS subnet groups need multi-AZ subnets)."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ (same order as var.azs)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ (same order as var.azs)."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway (+ Elastic IP) so private-subnet resources can reach the internet. Defaults to false to avoid the ~$0.045/hour + data processing cost of a NAT Gateway sitting idle in a portfolio/lab environment. Enable it only when something actually needs to run in a private subnet with outbound internet access."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "When enable_nat_gateway is true: true = one shared NAT Gateway for all AZs (cheaper, single point of failure — fine for dev/staging), false = one NAT Gateway per AZ (higher availability, higher cost — recommended for prod)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module. The mandatory tags (Environment/Project/ManagedBy/Owner/CostCenter) are normally already applied via the provider's default_tags — use this for module-specific extras only."
  type        = map(string)
  default     = {}
}
