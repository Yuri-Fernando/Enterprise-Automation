variable "name_prefix" {
  description = "Prefix used for naming all security group resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security groups belong to."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "web_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "web_ingress_port" {
  description = "Port the load balancer listens on for plain HTTP."
  type        = number
  default     = 80
}

variable "enable_https" {
  description = "Whether to also open 443 on the web security group."
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Port the application instances listen on, reachable only from the web security group."
  type        = number
  default     = 80
}

variable "admin_access_cidrs" {
  description = "CIDR blocks allowed direct SSH (Linux)/RDP (Windows) access to app instances. Empty by default — leave empty to force access via SSM Session Manager only (no open management port)."
  type        = list(string)
  default     = []
}

variable "os_type" {
  description = "\"linux\" opens port 22 (SSH) for admin_access_cidrs, \"windows\" opens port 3389 (RDP). Only relevant when admin_access_cidrs is non-empty."
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be \"linux\" or \"windows\"."
  }
}

variable "db_port" {
  description = "Port the database listens on, reachable only from the app security group."
  type        = number
  default     = 3306
}
