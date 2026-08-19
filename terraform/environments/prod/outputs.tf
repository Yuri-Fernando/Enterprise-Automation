output "vpc_id" {
  description = "ID of the VPC created for this environment."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer — open in a browser to hit the app."
  value       = module.compute.alb_dns_name
}

output "autoscaling_group_name" {
  value = module.compute.autoscaling_group_name
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)."
  value       = module.database.endpoint
}

output "db_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the auto-generated RDS master password."
  value       = module.database.master_user_secret_arn
}

output "github_actions_role_arn" {
  description = "Role ARN to configure as role-to-assume in GitHub Actions (OIDC, no long-lived keys)."
  value       = module.iam.github_actions_role_arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN that CloudWatch alarms notify (null if not created/configured)."
  value       = module.monitoring.sns_topic_arn
}
