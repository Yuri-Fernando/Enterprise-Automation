output "ec2_role_arn" {
  description = "ARN of the EC2 instance role (null if create_ec2_role = false)."
  value       = var.create_ec2_role ? aws_iam_role.ec2[0].arn : null
}

output "ec2_role_name" {
  description = "Name of the EC2 instance role (null if create_ec2_role = false)."
  value       = var.create_ec2_role ? aws_iam_role.ec2[0].name : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile, to attach to a Launch Template (null if create_ec2_role = false)."
  value       = var.create_ec2_role ? aws_iam_instance_profile.ec2[0].name : null
}

output "github_actions_role_arn" {
  description = "ARN of the role GitHub Actions assumes via OIDC (use as role-to-assume in aws-actions/configure-aws-credentials)."
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider in use (created by this module or the existing one passed in)."
  value       = local.github_oidc_provider_arn
}
