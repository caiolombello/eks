# Cluster Security Group
resource "aws_security_group" "cluster" {
  name_prefix = local.name_suffix
  description = "EKS cluster security group."
  vpc_id      = module.vpc.vpc_id
  tags = merge(var.tags, {
    "Name"                                       = "${local.name_suffix}-eks-cluster-sg"
    "kubernetes.io/cluster/${local.name_suffix}" = "owned"
  })
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

# Create EKS Cluster
resource "aws_eks_cluster" "this" {
  name                      = "${local.name_suffix}-${local.environment}"
  version                   = var.cluster_version
  role_arn                  = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api", "audit"] #Enable audit logs

  vpc_config {
    subnet_ids              = data.aws_subnets.subnet-private.ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.ClusterIAMFullAccess,
    aws_cloudwatch_log_group.this
  ]
  tags = var.resource_tags
}

resource "aws_cloudwatch_log_group" "this" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${local.name_suffix}/cluster"
  retention_in_days = 7
}


# Active CSI Driver for use to EBS
resource "aws_eks_addon" "CSI" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on = [
    aws_eks_node_group.workers
  ]
}

# Node Groups
resource "aws_eks_node_group" "workers" {
  for_each               = local.node_groups_expanded
  node_group_name        = lookup(each.value, "name", null)
  node_group_name_prefix = lookup(each.value, "name", null) == null ? "${local.name_suffix}-${each.key}" : null
  cluster_name           = aws_eks_cluster.this.id
  node_role_arn          = aws_iam_role.workers.arn # IAM Role that provides permissions for the EKS Node Group.
  subnet_ids             = [data.aws_subnets.subnet-private.ids[1]]
  ami_type               = lookup(each.value, "ami_type", null) # Type of Amazon Machine Image (AMI) associated with the EKS Node Group
  disk_size              = lookup(each.value, "disk_size", null)
  instance_types         = lookup(each.value, "instance_types", null)
  release_version        = lookup(each.value, "ami_release_version", null)  # AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version.
  capacity_type          = lookup(each.value, "capacity_type", null)        # Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT
  force_update_version   = lookup(each.value, "force_update_version", null) # Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
  labels                 = lookup(var.node_groups[each.key], "k8s_labels", {})
  tags                   = var.resource_tags


  scaling_config {
    desired_size = each.value["desired_capacity"]
    max_size     = each.value["max_capacity"]
    min_size     = each.value["min_capacity"]
  }

  update_config {
    max_unavailable = each.value["desired_capacity"] #Desired max number of unavailable worker nodes during node group update.
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taints", null) != null ? each.value["taints"] : []

    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  #lifecycle { #Optional: Allow external changes without Terraform plan difference
  #  create_before_destroy = true
  #  ignore_changes        = [scaling_config[0].desired_size]
  #}

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.WorkersIAMFullAccess,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

# Data
#Retrieve public subnet
data "aws_subnets" "subnet-public" {
  filter {
    name   = "tag:${local.name_suffix}-${local.environment}-public"
    values = ["shared"]
  }
}

#Retrieve private subnet
data "aws_subnets" "subnet-private" {
  filter {
    name   = "tag:${local.name_suffix}-${local.environment}-private"
    values = ["shared"]
  }
}

# Schedule
resource "aws_autoscaling_schedule" "monrise" {
  for_each               = var.node_groups
  scheduled_action_name  = "monrise"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * MON-FRI"
  start_time             = "${local.today_date}T21:00:00Z" #UTC time
  time_zone              = "America/Sao_Paulo"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
}

resource "aws_autoscaling_schedule" "sunrise" {
  for_each               = var.node_groups
  scheduled_action_name  = "sunrise"
  min_size               = 4
  max_size               = 6
  desired_capacity       = 4
  recurrence             = "0 7 * * MON-FRI"
  start_time             = "${local.tomorrow_date}T12:00:00Z" #UTC time
  time_zone              = "America/Sao_Paulo"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
}

# Autoscaling
# CPU Autoscale
resource "aws_autoscaling_policy" "cpu_scale_up_policy" {
  for_each               = var.node_groups
  name                   = "cpu_scale_up_policy"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 80.0
  }

  depends_on = [
    aws_eks_node_group.workers
  ]
}

# Outputs 
output "cluster_endpoint" {
  description = "Endpoint da API do cluster Kubernetes."
  value       = aws_eks_cluster.this.endpoint
}