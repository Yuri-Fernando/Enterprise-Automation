variable "name_prefix" {
  description = "Prefix used for naming all compute resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID the ALB and target group belong to."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the Application Load Balancer (needs at least 2, different AZs)."
  type        = list(string)
}

variable "instance_subnet_ids" {
  description = "Subnets where Auto Scaling Group instances launch. Pass public subnets when the networking module's enable_nat_gateway = false (instances need a public IP to reach the internet for package installs / SSM); pass private subnets when a NAT Gateway is enabled."
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Security group ID attached to the ALB (from the security module)."
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID attached to instances (from the security module)."
  type        = string
}

variable "os_type" {
  description = "\"linux\" (Amazon Linux 2023) or \"windows\" (Windows Server 2022) — selects the AMI and default user_data."
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be \"linux\" or \"windows\"."
  }
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is AWS free-tier-eligible and the default for this lab-scale project."
  type        = string
  default     = "t3.micro"
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name to attach (from the iam module's ec2_instance_profile_name output). Leave null to launch without one."
  type        = string
  default     = null
}

variable "key_name" {
  description = "EC2 key pair name for SSH/RDP access. Leave null to rely on SSM Session Manager only (recommended — avoids distributing/rotating key material)."
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Whether launched instances get a public IP. Should be true when instance_subnet_ids are public subnets (no NAT Gateway), false when they are private subnets behind a NAT Gateway."
  type        = bool
  default     = true
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 20
}

variable "user_data" {
  description = "Override the default user_data script. Leave null to use this module's minimal smoke-test web server (installs+starts a basic HTTP server so the ALB health check has something to pass against)."
  type        = string
  default     = null
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

variable "health_check_grace_period" {
  description = "Seconds the ASG waits after an instance launches before treating a failed ELB health check as a real failure."
  type        = number
  default     = 300
}

variable "app_port" {
  description = "Port the application/instances listen on, targeted by the ALB target group."
  type        = number
  default     = 80
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS (443) listener on the ALB. Requires certificate_arn."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Required when enable_https_listener = true."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB (recommended true for prod)."
  type        = bool
  default     = false
}
