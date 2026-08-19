output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "Connection endpoint (host:port) of the RDS instance."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the RDS instance, without the port (use with the `port` output when the two are needed separately)."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port the RDS instance listens on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database created on the instance."
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username configured on the instance."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the auto-generated master password (null unless manage_master_user_password = true)."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group created for this instance."
  value       = aws_db_subnet_group.this.name
}
