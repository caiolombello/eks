# Set up the CloudWatch agent to collect cluster metrics
resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_secret" "cloudwatch_agent_secret" {
  type = "kubernetes.io/service-account-token"
  metadata {
    name      = "cloudwatch-agent-token"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = "cloudwatch-agent"
    }
  }
}

resource "kubernetes_service_account" "cloudwatch_agent" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }

  secret {
    name = kubernetes_secret.cloudwatch_agent_secret.metadata[0].name
  }
}


resource "kubernetes_cluster_role" "cloudwatch_agent_role" {
  metadata {
    name = "cloudwatch-agent-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "endpoints"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/proxy"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/stats", "configmaps", "events"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cwagent-clusterleader"]
    verbs          = ["get", "update"]
  }

  depends_on = [
    kubernetes_namespace.amazon_cloudwatch
  ]
}

resource "kubernetes_cluster_role_binding" "cloudwatch_agent_role_binding" {
  metadata {
    name = "cloudwatch-agent-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cloudwatch_agent.metadata[0].name
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cloudwatch_agent_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_service_account.cloudwatch_agent,
    kubernetes_secret.cloudwatch_agent_secret,
    kubernetes_cluster_role.cloudwatch_agent_role,
    kubernetes_namespace.amazon_cloudwatch
  ]
}

resource "kubernetes_config_map" "cwagentconfig" {
  metadata {
    name      = "cwagentconfig"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "cwagentconfig.json" = jsonencode({
      "logs" = {
        "metrics_collected" = {
          "kubernetes" = {
            "cluster_name"                = data.terraform_remote_state.eks.outputs.cluster_name
            "metrics_collection_interval" = 60
          }
        }
        "force_flush_interval" = 5
      }
    })
  }

  depends_on = [
    kubernetes_namespace.amazon_cloudwatch
  ]
}


resource "kubernetes_manifest" "cloudwatch_agent" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "DaemonSet"
    metadata = {
      name      = "cloudwatch-agent"
      namespace = "amazon-cloudwatch"
    }
    spec = {
      selector = {
        matchLabels = {
          name = "cloudwatch-agent"
        }
      }
      template = {
        metadata = {
          labels = {
            name = "cloudwatch-agent"
          }
        }
        spec = {
          containers = [
            {
              name  = "cloudwatch-agent"
              image = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:1.247358.0b252413"
              resources = {
                limits = {
                  cpu    = "200m"
                  memory = "200Mi"
                }
                requests = {
                  cpu    = "200m"
                  memory = "200Mi"
                }
              }
              env = [
                {
                  name = "HOST_IP"
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "status.hostIP"
                    }
                  }
                },
                {
                  name = "HOST_NAME"
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "spec.nodeName"
                    }
                  }
                },
                {
                  name = "K8S_NAMESPACE"
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "metadata.namespace"
                    }
                  }
                },
                {
                  name  = "CI_VERSION"
                  value = "k8s/1.3.13"
                }
              ]
              volumeMounts = [
                {
                  name      = "cwagentconfig"
                  mountPath = "/etc/cwagentconfig"
                },
                {
                  name      = "rootfs"
                  mountPath = "/rootfs"
                },
                {
                  name      = "dockersock"
                  mountPath = "/var/run/docker.sock"
                },
                {
                  name      = "varlibdocker"
                  mountPath = "/var/lib/docker"
                },
                {
                  name      = "containerdsock"
                  mountPath = "/run/containerd/containerd.sock"
                },
                {
                  name      = "sys"
                  mountPath = "/sys"
                },
                {
                  name      = "devdisk"
                  mountPath = "/dev/disk"
                }
              ]
            }
          ]
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          volumes = [
            {
              name = "cwagentconfig"
              configMap = {
                name = "cwagentconfig"
              }
            },
            {
              name = "rootfs"
              hostPath = {
                path = "/"
              }
            },
            {
              name = "dockersock"
              hostPath = {
                path = "/var/run/docker.sock"
              }
            },
            {
              name = "varlibdocker"
              hostPath = {
                path = "/var/lib/docker"
              }
            },
            {
              name = "containerdsock"
              hostPath = {
                path = "/run/containerd/containerd.sock"
              }
            },
            {
              name = "sys"
              hostPath = {
                path = "/sys"
              }
            },
            {
              name = "devdisk"
              hostPath = {
                path = "/dev/disk/"
              }
            }
          ]
          terminationGracePeriodSeconds = 60
          serviceAccountName            = "cloudwatch-agent"
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.amazon_cloudwatch,
    kubernetes_secret.cloudwatch_agent_secret,
    kubernetes_service_account.cloudwatch_agent,
    kubernetes_config_map.cwagentconfig
  ]
}
