provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path = try(data.local_file.kubeconfig.filename, "")
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name} --kubeconfig ${path.module}/temp_kubeconfig.yaml"
  }
}

resource "null_resource" "delete_kubeconfig" {
  triggers = {
    kubeconfig = data.local_file.kubeconfig.filename
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/temp_kubeconfig.yaml"
  }

  depends_on = [
    null_resource.update_kubeconfig,
    aws_eks_cluster.this,
    aws_eks_node_group.workers
  ]
}


data "local_file" "kubeconfig" {
  filename = "${path.module}/temp_kubeconfig.yaml"

  depends_on = [
    null_resource.update_kubeconfig,
    aws_eks_cluster.this,
    aws_eks_node_group.workers
  ]
}

