resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "41.5.1"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/kube-prometheus-stack.yaml")]

  # set {
  #   name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
  #   value = kubernetes_persistent_volume.prometheus_pv.spec[0].capacity.storage
  # }

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium,
    # kubernetes_persistent_volume.prometheus_pv
  ]
}

resource "helm_release" "prometheus_adapter" {
  name       = "prometheus-adapter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-adapter"
  version    = "4.2.0"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/prometheus-adapter.yaml")]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.56.1"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/grafana.yaml")]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium,
    helm_release.kube_prometheus_stack,
    kubernetes_config_map.app_overview_dashboard,
    kubernetes_config_map.homepage_dashboard
  ]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.2.1"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/tempo.yaml")]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.10"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/loki.yaml")]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium
  ]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.11.1"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  values = [file("${path.module}/values/promtail.yaml")]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.cilium
  ]
}
