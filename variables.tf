variable "aws_region" {
  description = "The AWS region your resources will be deployed"
}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Environment = "dev",
    Terraform   = "true"
    Owner       = "Caio Barbieri"
    Name        = "eks-devops"
  }
}

variable "tags" {
  description = "Um mapa de tags para ser adicionada em todos os recursos."
  type        = map(string)
  default     = {}
}

# VPC
variable "cidr_block" {
  description = "VPC's CIDR block."
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets list created on VPC."
  type        = list(string)
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnets list created on VPC."
  type        = list(string)
  default     = ["10.50.5.0/24", "10.50.6.0/24"]
}

# Cluster
variable "cluster_version" {
  description = "Versão do Kubernetes para o cluster EKS."
  type        = string
  default     = "1.27"
}

variable "cluster_enabled_log_types" {
  description = "Lista de logs do control plane que deseja habilitar. Para mais informações, acesse a documentação do Amazon EKS Control Plane Logging (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)."
  type        = list(string)
  default     = []
}

variable "cluster_log_retention_in_days" {
  description = "Tempo de vida dos logs definido em dias."
  type        = number
  default     = 90
}

variable "cluster_endpoint_private_access" {
  description = "Indica se o endpoint privado da API do Amazon EKS está habilitado."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indica se o endpoint público da API do Amazon EKS está habilitado. Quando atribuído `false`, certifique-se de ter um acesso privado adequado com o `cluster_endpoint_private_access = true`."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_ipv4_cidr" {
  description = "Bloco CIDR que deve ser atribuído ao endereço IP do serviço do Kubernetes. Se você não for especificado um bloco, o Kubernetes atribuirá endereços dos blocos CIDR `10.100.0.0/16` ou `172.20.0.0/16`."
  type        = string
  default     = null
}

variable "cluster_create_timeout" {
  description = "Timeout da criação do cluster EKS."
  type        = string
  default     = "30m"
}

variable "cluster_delete_timeout" {
  description = "Timeout da destruição do cluster EKS."
  type        = string
  default     = "15m"
}

# Node Groups
variable "node_groups" {
  description = "Map de maps para criação dos node groups. Exemplo: `node_groups = { example = { ... } }`."
  type        = any
  default = {
    DevOps = {
      desired_capacity = 3
      max_capacity     = 4
      min_capacity     = 3
      instance_types   = ["m7g.xlarge"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 10
    }
  }
}

variable "taints" {
  description = "List of taints to apply to the node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = [
    {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  ]
}

variable "aws_launch_configuration" {
  description = "Map de maps para criação de schedule actions nos node groups."
  type        = any
  default     = {}
}

variable "node_groups_schedule" {
  description = "Map de maps para criação de schedule actions nos node groups."
  type        = any
  default     = {}
}

# Security Group
variable "cluster_egress_cidrs" {
  description = "Lista de blocos CIDRs permitidos no tráfego de saída do cluster."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Kubeconfig
variable "create_kubeconfig" {
  description = "Se `true` o arquivo kubeconfig será criado."
  type        = bool
  default     = true
}


# IAM
variable "iam_cluster_role_name" {
  description = "Nome da role utilizada pelo cluster EKS."
  type        = string
  default     = ""
}

variable "iam_workers_role_name" {
  description = "Nome da role utilizada pelos Nodde Groups do cluster EKS."
  type        = string
  default     = ""
}

# Autoscaling
variable "scaling_period" {
  type    = list(string)
  default = ["600", "1200", "1800"]
}

# Logging
variable "cloudwatch_namespace" {
  description = "Namespace"
  type        = string
  default     = "amazon-cloudwatch"
}

variable "fluent_bit" {
  description = "Map para o fluent_bit"
  type        = any
  default = {
    DevOps = {
      "http.server" = "off"
      "http.port"   = "2020"
      "read.head"   = "On"
      "read.tail"   = "Off"
    }
  }
}
