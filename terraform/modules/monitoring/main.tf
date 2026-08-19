# ---------------------------------------------------------------------------
# Generic CloudWatch monitoring: optional SNS topic, EC2/ASG alarms, ALB
# alarms, RDS alarms, and application log groups. Every alarm group is
# opt-in (enable_* = false by default) so an environment only pays for the
# metrics/alarms it actually wires up — nothing here creates cost on its own
# beyond the (free-tier-eligible) CloudWatch alarms themselves.
# ---------------------------------------------------------------------------

# --- SNS topic (optional) ---------------------------------------------------

resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.name_prefix}-alarms"
  tags  = merge(var.tags, { Name = "${var.name_prefix}-alarms" })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

locals {
  # Resolve to: this module's own topic > an externally-passed topic > no
  # topic at all (alarms are still created, just without an alarm_actions
  # target — useful for a dashboard-only setup).
  notify_arn    = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : var.sns_topic_arn
  alarm_actions = local.notify_arn != "" ? [local.notify_arn] : []
}

# --- EC2 / Auto Scaling Group alarms ----------------------------------------

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  count = var.enable_ec2_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-asg-cpu-high"
  alarm_description   = "Average CPU utilization across the Auto Scaling Group is above ${var.cpu_high_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-asg-cpu-high" })
}

resource "aws_cloudwatch_metric_alarm" "asg_status_check_failed" {
  count = var.enable_ec2_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-asg-status-check-failed"
  alarm_description   = "One or more instances in the Auto Scaling Group are failing an EC2 status check."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-asg-status-check-failed" })
}

# --- Application Load Balancer alarms (optional) ----------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-5xx-high"
  alarm_description   = "The load balancer generated more than ${var.alb_5xx_threshold} 5xx responses in a single period."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-5xx-high" })
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  alarm_description   = "One or more targets behind the load balancer are unhealthy."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-unhealthy-hosts" })
}

# --- RDS alarms (optional) --------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU utilization is above ${var.db_cpu_high_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.db_cpu_high_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-cpu-high" })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS free storage space is below ${var.db_free_storage_threshold_bytes} bytes."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.db_free_storage_threshold_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-free-storage-low" })
}

# --- Log groups --------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(var.log_group_names)

  name              = each.value
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = each.value })
}
