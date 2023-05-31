provider "kubernetes" {
  config_path = "../kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "../kubeconfig.yaml"
  }
}

resource "kubernetes_manifest" "serviceMonitorCRD" {
  manifest = yamldecode(file("ServiceMonitorCRD.yaml"))
}
