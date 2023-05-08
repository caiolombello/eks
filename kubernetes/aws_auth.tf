# Access EKS with AWS CLI
## Apply IAM Root User
resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "root-aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = jsonencode([{
      userarn  = data.terraform_remote_state.eks.outputs.root_user_arn
      username = data.terraform_remote_state.eks.outputs.root_user_name
      groups   = ["system:masters"]
    }])
  }
}

# Developer User
resource "kubernetes_role" "developer" {
  metadata {
    name      = "developer"
    namespace = "default"
  }

  rule {
    api_groups = ["*"]
    resources  = ["pods", "services", "deployments", "replicasets", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}


resource "kubernetes_role_binding" "developer" {
  metadata {
    name      = "developer"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.developer.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = data.terraform_remote_state.eks.outputs.developer_arn
    api_group = "rbac.authorization.k8s.io"
  }
}
