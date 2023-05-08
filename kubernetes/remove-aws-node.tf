resource "null_resource" "remove_aws_node_daemonset" {
  provisioner "local-exec" {
    command = "${path.module}/remove_aws_node_daemonset.sh"
  }
  triggers = {
    timestamp = timestamp()
  }
}
