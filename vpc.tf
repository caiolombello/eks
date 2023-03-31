# VPC
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = ">= 3.16.0" # Last version on 07/10/2022
  name                 = "${local.name_suffix}-${local.environment}"
  cidr                 = var.cidr_block
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = var.resource_tags

  public_subnet_tags = {
    "${local.name_suffix}-${local.environment}-public" = "shared"
  }

  private_subnet_tags = {
    "${local.name_suffix}-${local.environment}-private" = "shared"
  }
}

# Logs
# Create bucket for storage the vpc logs
resource "aws_s3_bucket" "this" {
  bucket        = "logs-vpc-${local.name_suffix}-${local.environment}"
  force_destroy = true
  tags          = var.resource_tags
}

# Active de logs on VPC
resource "aws_flow_log" "liferay" {
  log_destination      = aws_s3_bucket.this.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
}


# Data
# Retrieve avaibility zones
data "aws_availability_zones" "available" {}

# Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

