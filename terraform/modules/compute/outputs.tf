output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB, used as a CloudWatch metric dimension (e.g. by the monitoring module)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group, used as a CloudWatch metric dimension."
  value       = aws_lb_target_group.this.arn_suffix
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group (used as a CloudWatch metric dimension by the monitoring module)."
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID of the Launch Template."
  value       = aws_launch_template.this.id
}

output "ami_id" {
  description = "AMI ID resolved for the selected os_type."
  value       = local.ami_id
}
