# EKS — control plane + managed node group + add-ons + access entries + IRSA.
# Origem: módulo mínimo do Argus (terraform/modules/aws/eks), promovido para a plataforma e completado com os
# padrões do workshop DevOps na Nuvem (access entries em modo API, add-ons gerenciados, OIDC/IRSA).
# Funciona na AWS real e no floci (onde o cluster vira um k3s real; node group/add-ons são metadados).

locals {
  oidc_issuer = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, "")
}

# ---------------------------------------------------------------------------
# IAM — control plane
# ---------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each   = toset(["AmazonEKSClusterPolicy"])
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name                      = var.name
  version                   = var.kubernetes_version
  role_arn                  = aws_iam_role.cluster.arn
  enabled_cluster_log_types = var.cluster_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
  tags       = var.tags
}

# ---------------------------------------------------------------------------
# IAM — nós
# ---------------------------------------------------------------------------
resource "aws_iam_role" "node" {
  name = "${var.name}-eks-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each   = toset(["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"])
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-${var.node_group.name}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.node_subnet_ids != null ? var.node_subnet_ids : var.subnet_ids
  instance_types  = var.node_group.instance_types
  capacity_type   = var.node_group.capacity_type
  disk_size       = var.node_group.disk_size

  scaling_config {
    desired_size = var.node_group.desired_size
    min_size     = var.node_group.min_size
    max_size     = var.node_group.max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.node]
  tags       = var.tags
}

# ---------------------------------------------------------------------------
# Add-ons gerenciados
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "this" {
  for_each                    = var.addons
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.default]
  tags                        = var.tags
}

# ---------------------------------------------------------------------------
# Access entries (modo API) — quem administra o cluster sem editar aws-auth
# ---------------------------------------------------------------------------
resource "aws_eks_access_entry" "this" {
  for_each      = var.access_entries
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
  tags          = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each      = var.access_entries
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/${each.value.policy}"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}

# ---------------------------------------------------------------------------
# IRSA — provider OIDC do cluster (pods assumem roles IAM via service account)
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "irsa" {
  count          = var.enable_irsa ? 1 : 0 # o issuer só é conhecido após criar o cluster: não pode decidir o count
  url            = local.oidc_issuer
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}
