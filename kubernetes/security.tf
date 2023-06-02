resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
  }
}

resource "helm_release" "kyverno" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "3.0.1"
  namespace  = kubernetes_namespace.security.metadata[0].name

  depends_on = [
    kubernetes_namespace.security,
    # helm_release.cilium,
  ]
}

# Policies
resource "null_resource" "disallow_root_user" {
  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig ../kubeconfig.yaml -f ${path.module}/policies"
  }

  triggers = {
    kyverno_id = helm_release.kyverno.id
  }
}

