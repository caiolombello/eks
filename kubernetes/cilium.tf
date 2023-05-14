resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "monitoring"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.13.2"

  set {
    name  = "eni.enabled"
    value = "true"
  }

  set {
    name  = "ipam.mode"
    value = "eni"
  }

  set {
    name  = "egressMasqueradeInterfaces"
    value = "eth0"
  }

  set {
    name  = "tunnel"
    value = "disabled"
  }

  set {
    name  = "nodeinit.enabled"
    value = "true"
  }

  # Hubble enabled
  set {
    name  = "hubble.listenAddress"
    value = ":4244"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "false"
  }

  # Cilium Metrics Enabled

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name = "prometheus.serviceMonitor.enabled"
    value = "true"
  }

  # set {
  #   name = "prometheus.serviceMonitor.labels"
  #   value = jsonencode({ release: "prometheus" })
  # }

  set {
    name  = "operator.prometheus.enabled"
    value = "true"
  }

  set {
    name = "operator.prometheus.serviceMonitor.enabled"
    value = "true"
  }

  # set {
  #   name  = "operator.prometheus.serviceMonitor.labels"
  #   value = jsonencode({ release: "prometheus" })
  # }

  # Hubble Metrics Enabled

  set {
    name  = "hubble.metrics.enableOpenMetrics"
    value = "true"
  }

  set {
    name = "hubble.metrics.serviceMonitor.enabled"
    value = "true"
  }

  # set {
  #   name = "hubble.metrics.serviceMonitor.labels"
  #   value = jsonencode({ release: "prometheus" })
  # }

  set {
    name  = "hubble.metrics.enabled"
    value = "{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\\,source_namespace\\,source_workload\\,destination_ip\\,destination_namespace\\,destination_workload\\,traffic_direction;sourceContext=workload-name|pod-name|reserved-identity;destinationContext=workload-name|pod-name|reserved-identity}"
  }

  set {
    name = "hubble.metrics.dashboards.enabled"
    value = "true"
  }

  set {
    name = "hubble.metrics.dashboards.namespace"
    value = "monitoring"
  }

  depends_on = [ 
    helm_release.kube_prometheus_stack 
  ]
}
