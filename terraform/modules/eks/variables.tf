variable "name" {
  description = "Nome do cluster EKS."
  type        = string
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes do control plane."
  type        = string
  default     = "1.33"
}

variable "subnet_ids" {
  description = "Subnets do control plane (mínimo 2 AZs)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets do node group. null = usa subnet_ids. Em lab sem NAT, use subnets públicas."
  type        = list(string)
  default     = null
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  description = "CIDRs com acesso ao endpoint público. Restrinja ao seu IP fora do lab."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "Logs do control plane enviados ao CloudWatch (custo na AWS real; vazio = nenhum)."
  type        = list(string)
  default     = []
}

variable "node_group" {
  description = "Configuração do managed node group. SPOT reduz custo na AWS real."
  type = object({
    name           = string
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    desired_size   = number
    min_size       = number
    max_size       = number
  })
  default = {
    name           = "default"
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
    disk_size      = 20
    desired_size   = 2
    min_size       = 1
    max_size       = 3
  }

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group.capacity_type)
    error_message = "capacity_type deve ser ON_DEMAND ou SPOT."
  }
}

variable "addons" {
  description = "Add-ons gerenciados: nome => versão (null = padrão da versão do cluster)."
  type        = map(string)
  default = {
    "vpc-cni"                = null
    "coredns"                = null
    "kube-proxy"             = null
    "eks-pod-identity-agent" = null
  }
}

variable "access_entries" {
  description = "Principais IAM com acesso ao cluster: chave => { principal_arn, policy (ex.: AmazonEKSClusterAdminPolicy) }."
  type = map(object({
    principal_arn = string
    policy        = string
  }))
  default = {}
}

variable "enable_irsa" {
  description = "Cria o provider OIDC do cluster para IRSA."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
