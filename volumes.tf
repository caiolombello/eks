resource "aws_ebs_volume" "prometheus_volume" {
  availability_zone = module.vpc.azs[0]
  size              = 5
  type              = "gp2"
  tags = {
    Name = "prometheus-prometheus-prometheus-db"
  }
}

output "prometheus_volume_id" {
  description = "The ID of the Prometheus EBS volume."
  value       = aws_ebs_volume.prometheus_volume.id
}

output "vpc_first_az" {
  description = "The first Availability Zone in the VPC."
  value       = module.vpc.azs[0]
}
