output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  value     = try(aws_eks_cluster.this.certificate_authority[0].data, null)
  sensitive = true
}

output "cluster_security_group_id" {
  value = try(aws_eks_cluster.this.vpc_config[0].cluster_security_group_id, null)
}

output "oidc_issuer" {
  value = local.oidc_issuer
}

output "oidc_provider_arn" {
  value = try(aws_iam_openid_connect_provider.irsa[0].arn, null)
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}
