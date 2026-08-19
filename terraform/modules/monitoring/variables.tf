variable "name_prefix" {
  description = "Prefix used for naming all monitoring resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

# --- SNS (optional) --------------------------------------------------------

variable "create_sns_topic" {
  description = "Whether to create an SNS topic that CloudWatch alarms publish to. Set false and pass sns_topic_arn instead to reuse an existing topic. Leave both false/empty to create alarms with no action (dashboard-only)."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN to notify on alarm state changes. Ignored when create_sns_topic = true (this module's own topic is used instead). Leave empty for no notifications."
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address subscribed to the SNS topic when create_sns_topic = true. Leave empty to create the topic without a subscription (subscribe manually later)."
  type        = string
  default     = ""
}

# --- EC2 / Auto Scaling Group alarms ---------------------------------------

variable "enable_ec2_alarms" {
  description = "Whether to create the EC2/ASG CPU and status-check alarms. Requires autoscaling_group_name."
  type        = bool
  default     = false
}

variable "autoscaling_group_name" {
  description = "Auto Scaling Group name to monitor (from the compute module's autoscaling_group_name output). Required when enable_ec2_alarms = true."
  type        = string
  default     = ""
}

variable "cpu_high_threshold" {
  description = "Average CPU utilization percentage that triggers the high-CPU alarm."
  type        = number
  default     = 80
}

variable "cpu_alarm_evaluation_periods" {
  description = "Number of consecutive periods CPU must breach the threshold before the alarm fires."
  type        = number
  default     = 3
}

variable "cpu_alarm_period_seconds" {
  description = "Length, in seconds, of each CloudWatch evaluation period for the CPU alarm."
  type        = number
  default     = 300
}

# --- Application Load Balancer alarms (optional) ---------------------------

variable "enable_alb_alarms" {
  description = "Whether to create ALB 5xx and unhealthy-host-count alarms. Requires alb_arn_suffix and target_group_arn_suffix."
  type        = bool
  default     = false
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (from the compute module's alb_arn_suffix output). Required when enable_alb_alarms = true."
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group (from the compute module's target_group_arn_suffix output). Required when enable_alb_alarms = true."
  type        = string
  default     = ""
}

variable "alb_5xx_threshold" {
  description = "Number of ALB-generated 5xx responses in a single period that triggers the alarm."
  type        = number
  default     = 10
}

# --- RDS alarms (optional) --------------------------------------------------

variable "enable_rds_alarms" {
  description = "Whether to create RDS CPU and free-storage alarms. Requires db_instance_id."
  type        = bool
  default     = false
}

variable "db_instance_id" {
  description = "RDS instance identifier to monitor (from the database module's db_instance_id output). Required when enable_rds_alarms = true."
  type        = string
  default     = ""
}

variable "db_cpu_high_threshold" {
  description = "Average CPU utilization percentage that triggers the RDS high-CPU alarm."
  type        = number
  default     = 80
}

variable "db_free_storage_threshold_bytes" {
  description = "Free storage space, in bytes, below which the RDS low-storage alarm fires. Default is 2 GiB."
  type        = number
  default     = 2147483648
}

# --- Log groups --------------------------------------------------------------

variable "log_group_names" {
  description = "Application/system log group names to create (e.g. [\"/enterprise-cloud-automation/dev/app\"]). Empty by default — pass explicit names per environment."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention, in days, for every log group created by this module. 0 = never expire."
  type        = number
  default     = 30
}
