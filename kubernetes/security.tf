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
    helm_release.cilium,
  ]
}

# Policies
resource "null_resource" "disallow_root_user" {
  depends_on = [helm_release.kyverno, helm_release.cilium]

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig ../kubeconfig.yaml -f ${path.module}/policies/disallow-root-user.yaml"
  }
}

