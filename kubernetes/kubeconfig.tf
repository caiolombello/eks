# Access EKS with Kubeconfig
## Developer User
resource "kubernetes_cluster_role" "developer" {
  metadata {
    name = "developer-role"
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "ingresses", "nodes", "metrics"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

}

resource "kubernetes_cluster_role_binding" "developer" {
  metadata {
    name = "developer-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.developer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.developer.metadata[0].name
    namespace = kubernetes_service_account.developer.metadata[0].namespace
  }

  depends_on = [ 
    kubernetes_cluster_role.developer,
    kubernetes_service_account.developer
   ]

}

resource "kubernetes_service_account" "developer" {
  metadata {
    name      = "developer"
    namespace = "default"
  }
}

resource "kubernetes_secret" "developer" {
  metadata {
    name = kubernetes_service_account.developer.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.developer.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

## Create Developer Kubeconfig
data "template_file" "kubeconfig" {
  count = data.terraform_remote_state.eks.outputs.environment == "dev" ? 1 : 0

  template = file("${path.module}/kubeconfig.tpl")

  vars = {
    cluster_name          = data.terraform_remote_state.eks.outputs.cluster_name
    endpoint              = data.terraform_remote_state.eks.outputs.cluster_endpoint 
    certificate_authority = data.terraform_remote_state.eks.outputs.cluster_certificate_authority
    token                 = kubernetes_secret.developer.data.token
    service_account_name  = kubernetes_service_account.developer.metadata[0].name
  }

  depends_on = [
    kubernetes_service_account.developer,
    kubernetes_secret.developer,
    kubernetes_cluster_role_binding.developer
  ]
}

resource "local_file" "kubeconfig" {
  count    = data.terraform_remote_state.eks.outputs.environment == "dev" ? 1 : 0
  content  = count.index == 0 ? data.template_file.kubeconfig[0].rendered : null
  filename = "${path.module}/kubeconfig-${data.terraform_remote_state.eks.outputs.cluster_name}-developer.yaml"

  depends_on = [
    data.template_file.kubeconfig
  ]
}

output "kubeconfig" {
  description = "The kubeconfig for the developer service account"
  value       = data.terraform_remote_state.eks.outputs.environment == "dev" ? try(local_file.kubeconfig[0].content, null) : null
  sensitive   = false
}