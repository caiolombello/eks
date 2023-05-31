# resource "kubernetes_persistent_volume" "prometheus_pv" {
#   metadata {
#     name = "prometheus-prometheus-prometheus-db"
#   }
#   spec {
#     storage_class_name = "gp2"
#     # claim_ref {
#     #   name      = "db-prometheus-prometheus-prometheus-0"
#     #   namespace = "monitoring"
#     # }
#     capacity = {
#       storage = "10Gi"
#     }

#     access_modes = ["ReadWriteOnce"]
#     persistent_volume_reclaim_policy = "Retain"    
#     persistent_volume_source {
#       aws_elastic_block_store {
#         volume_id = data.terraform_remote_state.eks.outputs.prometheus_volume_id
#         fs_type   = "ext4"
#       }
#     }
#   }
# }