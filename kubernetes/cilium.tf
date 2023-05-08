resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
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
    value = "true"
  }

  # Cilium Metrics Enabled

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "operator.prometheus.enabled"
    value = "true"
  }

  # Hubble Metrics Enabled

  set {
    name  = "hubble.metrics.enableOpenMetrics"
    value = "true"
  }

  set {
    name  = "hubble.metrics.enabled"
    value = "{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\\,source_namespace\\,source_workload\\,destination_ip\\,destination_namespace\\,destination_workload\\,traffic_direction}"
  }
}