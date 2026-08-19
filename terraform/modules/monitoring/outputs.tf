output "sns_topic_arn" {
  description = "ARN of the SNS topic alarms notify (this module's own topic, the externally-passed one, or null when neither is set)."
  value       = local.notify_arn != "" ? local.notify_arn : null
}

output "ec2_alarm_names" {
  description = "Names of the EC2/ASG alarms created (empty when enable_ec2_alarms = false)."
  value = compact([
    try(aws_cloudwatch_metric_alarm.asg_cpu_high[0].alarm_name, ""),
    try(aws_cloudwatch_metric_alarm.asg_status_check_failed[0].alarm_name, ""),
  ])
}

output "alb_alarm_names" {
  description = "Names of the ALB alarms created (empty when enable_alb_alarms = false)."
  value = compact([
    try(aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_name, ""),
    try(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_name, ""),
  ])
}

output "rds_alarm_names" {
  description = "Names of the RDS alarms created (empty when enable_rds_alarms = false)."
  value = compact([
    try(aws_cloudwatch_metric_alarm.rds_cpu_high[0].alarm_name, ""),
    try(aws_cloudwatch_metric_alarm.rds_free_storage_low[0].alarm_name, ""),
  ])
}

output "log_group_names" {
  description = "Names of the CloudWatch log groups created by this module."
  value       = [for lg in aws_cloudwatch_log_group.this : lg.name]
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups created by this module."
  value       = [for lg in aws_cloudwatch_log_group.this : lg.arn]
}
