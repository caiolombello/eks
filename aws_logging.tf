resource "kubernetes_namespace" "cloudwatch_namespace" {
  metadata {
    name = var.cloudwatch_namespace
  }
}

resource "kubernetes_config_map" "fluent_bit_cluster_info" {
  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = var.cloudwatch_namespace
  }

  data = {
    "cluster.name" = aws_eks_cluster.this.name
    "http.server"  = var.fluent_bit["DevOps"]["http.server"]
    "http.port"    = "2020"
    "read.head"    = "On"
    "read.tail"    = "Off"
    "logs.region"  = var.aws_region
  }
}


resource "null_resource" "apply_fluent_bit_yaml" {

  triggers = {
    fluentconfig = kubernetes_config_map.fluent_bit_cluster_info.id
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig ${path.module}/kubeconfig.yaml -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  }

  depends_on = [
    kubernetes_namespace.cloudwatch_namespace,
    aws_eks_node_group.workers,
    kubernetes_config_map.fluent_bit_cluster_info
  ]
}

resource "null_resource" "delete_fluent_bit_yaml" {

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete --kubeconfig ${path.module}/kubeconfig.yaml -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  }

  depends_on = [
    kubernetes_namespace.cloudwatch_namespace,
    aws_eks_node_group.workers,
    kubernetes_config_map.fluent_bit_cluster_info
  ]
}
