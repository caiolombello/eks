locals {
  homepage_json                                   = jsondecode(file("dashboards/homepage.json"))
  app_overview_json                               = jsondecode(file("dashboards/app-overview.json"))
  cilium_dashboard_json                           = jsondecode(file("dashboards/cilium-dashboard.json"))
  hubble_dashboard_json                           = jsondecode(file("dashboards/hubble-dashboard.json"))
  grafana_hubble_l7_http_metrics_by_workload_json = jsondecode(file("dashboards/grafana-hubble-l7-http-metrics-by-workload.json"))
  flows_by_protocol_json                          = jsondecode(file("dashboards/flows-by-protocol.json"))
  http_connectivity_json                          = jsondecode(file("dashboards/http-connectivity.json"))
}

resource "kubernetes_config_map" "app_overview_dashboard" {
  metadata {
    name      = "app-overview"
    namespace = kubernetes_namespace.monitoring.metadata[0].name

    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "app-overview.json" = jsonencode(local.app_overview_json)
  }
}

resource "kubernetes_config_map" "homepage_dashboard" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name

    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "homepage.json" = jsonencode(local.homepage_json)
  }
}

# resource "kubernetes_config_map" "cilium_dashboard" {
#   metadata {
#     name      = "cilium-dashboard"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name

#     labels = {
#       grafana_dashboard = "true"
#     }
#   }

#   data = {
#     "cilium-dashboard.json" = jsonencode(local.cilium_dashboard_json)
#   }
# }

# resource "kubernetes_config_map" "hubble_dashboard" {
#   metadata {
#     name      = "hubble-dashboard"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name

#     labels = {
#       grafana_dashboard = "true"
#     }
#   }

#   data = {
#     "hubble-dashboard.json" = jsonencode(local.hubble_dashboard_json)
#   }
# }

# resource "kubernetes_config_map" "grafana_hubble_l7_http_metrics_by_workload" {
#   metadata {
#     name      = "grafana-hubble-l7-http-metrics-by-workload"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name

#     labels = {
#       grafana_dashboard = "true"
#     }
#   }

#   data = {
#     "grafana-hubble-l7-http-metrics-by-workload.json" = jsonencode(local.grafana_hubble_l7_http_metrics_by_workload_json)
#   }
# }

# resource "kubernetes_config_map" "flows_by_protocol_dashboard" {
#   metadata {
#     name      = "flows-by-protocol"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name

#     labels = {
#       grafana_dashboard = "true"
#     }
#   }

#   data = {
#     "flows-by-protocol.json" = jsonencode(local.flows_by_protocol_json)
#   }
# }

# resource "kubernetes_config_map" "http_connectivity_dashboard" {
#   metadata {
#     name      = "http-connectivity"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name

#     labels = {
#       grafana_dashboard = "true"
#     }
#   }

#   data = {
#     "http-connectivity.json" = jsonencode(local.http_connectivity_json)
#   }
# }