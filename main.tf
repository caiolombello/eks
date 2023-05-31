provider "aws" {
  region = var.aws_region
}

output "region" {
  description = "The AWS region."
  value       = var.aws_region
}