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
resource "aws_s3_bucket" "vpc" {
  bucket        = "logs-vpc-${local.name_suffix}-${local.environment}"
  force_destroy = true
  tags          = var.resource_tags
}

# Active de logs on VPC
resource "aws_flow_log" "liferay" {
  log_destination      = aws_s3_bucket.vpc.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
}


# Cluster Security Group
resource "aws_security_group" "cluster" {
  name_prefix = local.name_suffix
  description = "EKS cluster security group."
  vpc_id      = module.vpc.vpc_id
  tags = merge(var.tags, {
    "Name"                                                            = "${local.name_suffix}-eks-cluster-sg"
    "kubernetes.io/cluster/${local.name_suffix}-${local.environment}" = "owned"
  })
  depends_on = [
    module.vpc,
    module.vpc.aws_subnets
  ]
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description       = "Allow cluster egress access to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = var.cluster_egress_cidrs
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "cluster_https_worker_ingress" {
  description       = "Allow workstation to communicate with the EKS cluster API."
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = var.cluster_endpoint_public_access_cidrs
  from_port         = 443
  to_port           = 443
  type              = "ingress"
}


# Data
# Retrieve public subnet
data "aws_subnets" "subnet-public" {
  filter {
    name   = "tag:${local.name_suffix}-${local.environment}-public"
    values = ["shared"]
  }
  depends_on = [
    module.vpc
  ]
}

# Retrieve private subnet
data "aws_subnets" "subnet-private" {
  filter {
    name   = "tag:${local.name_suffix}-${local.environment}-private"
    values = ["shared"]
  }
  depends_on = [
    module.vpc
  ]
}

# Retrieve avaibility zones
data "aws_availability_zones" "available" {}

# Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}