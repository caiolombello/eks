resource "null_resource" "remove_aws_node_daemonset" {
  provisioner "local-exec" {
    command = "${path.module}/remove_aws_node_daemonset.sh"
  }
  triggers = {
    kube_prometheus_stack_id = helm_release.cilium.id
  }
}
