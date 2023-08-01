provider "aws" {
  region = var.aws_region
}

output "region" {
  description = "The AWS region."
  value       = var.aws_region
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "${path.module}/kubeconfig.yaml"
}