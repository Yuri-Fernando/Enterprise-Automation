# ---------------------------------------------------------------------------
# AWS Budgets: one monthly cost budget, scoped to this project's tagged
# resources only (not the whole AWS account), with email alerts at
# ACTUAL-spend thresholds plus one FORECASTED early warning.
#
# Never applied against a real AWS account in this repo (no billing/cost
# data to alert on until terraform apply happens for real -- see
# README.md "o que não foi feito"). `terraform validate` only, same as
# every other module here that hasn't been applied yet.
#
# aws_budgets_budget is a global (not regional) resource but the AWS
# provider still requires a configured region to call the Budgets API
# (us-east-1 is the only region Budgets' control plane lives in,
# regardless of which region the budgeted resources themselves run in --
# this is an AWS platform constraint, not a choice made here).
# ---------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.name_prefix}-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name = "TagKeyValue"
    # AWS Budgets' TagKeyValue filter wants the literal format
    # "user:<TagKey>$<TagValue>" -- format() avoids Terraform's
    # `$${...}` double-dollar escaping ambiguity (which would stop the
    # second variable from interpolating at all).
    values = [format("user:%s$%s", var.cost_filter_tag_key, var.cost_filter_tag_value)]
  }

  dynamic "notification" {
    for_each = var.alert_emails == [] ? [] : var.actual_thresholds_percent
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.alert_emails
    }
  }

  dynamic "notification" {
    for_each = var.alert_emails == [] ? [] : [var.forecasted_threshold_percent]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = var.alert_emails
    }
  }
}
