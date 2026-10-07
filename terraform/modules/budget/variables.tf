variable "name_prefix" {
  description = "Prefix used for naming the budget."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "monthly_limit_usd" {
  description = "Monthly cost budget limit, in USD."
  type        = string
  default     = "20"
}

variable "alert_emails" {
  description = "Email addresses notified when a threshold is breached. Empty by default -- pass real addresses per environment (see terraform.tfvars.example)."
  type        = list(string)
  default     = []
}

variable "actual_thresholds_percent" {
  description = "Percent-of-budget thresholds, evaluated against ACTUAL spend, that trigger a notification (e.g. [80, 100] notifies at 80% and 100% of monthly_limit_usd already spent)."
  type        = list(number)
  default     = [80, 100]
}

variable "forecasted_threshold_percent" {
  description = "Percent-of-budget threshold, evaluated against FORECASTED spend, that triggers an early-warning notification before the money is actually spent."
  type        = number
  default     = 100
}

variable "cost_filter_tag_key" {
  description = "Tag key used to scope this budget to only this project's resources (via AWS Budgets CostFilters), instead of the whole account. Matches the 'Project' default_tags key in terraform/providers.tf."
  type        = string
  default     = "Project"
}

variable "cost_filter_tag_value" {
  description = "Tag value this budget is scoped to (var.project_name in terraform/variables.tf)."
  type        = string
}
