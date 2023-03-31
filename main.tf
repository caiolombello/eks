terraform {
  required_version = ">= 1.3.1"

  # providers - 4.33.0 the last version on 04/10/2022
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Recupera o Kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name} --kubeconfig ${path.module}/temp_kubeconfig.yaml"
  }

  triggers = {
    cluster_id = aws_eks_cluster.this.id
  }
}

data "local_file" "kubeconfig" {
  depends_on = [null_resource.update_kubeconfig]
  filename   = "${path.module}/temp_kubeconfig.yaml"
}

provider "kubernetes" {
  config_path = data.local_file.kubeconfig.filename
}
