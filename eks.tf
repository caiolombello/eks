# Create EKS Cluster
resource "aws_eks_cluster" "this" {
  name                      = "${local.name_suffix}-${local.environment}"
  version                   = var.cluster_version
  role_arn                  = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"] # Enable audit logs

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    module.vpc,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.ClusterIAMFullAccess,
    aws_cloudwatch_log_group.cluster
  ]

  vpc_config {
    subnet_ids              = data.aws_subnets.subnet-private.ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.kms_key.arn
    }
    resources = ["secrets"]
  }

  tags = var.resource_tags
}

resource "aws_cloudwatch_log_group" "cluster" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${local.name_suffix}-${local.environment}/cluster"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
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
  for_each             = local.node_groups_expanded
  node_group_name      = lookup(each.value, "name", null) == null ? "nodes-${local.name_suffix}-${local.environment}" : null
  cluster_name         = aws_eks_cluster.this.id
  node_role_arn        = aws_iam_role.workers.arn # IAM Role that provides permissions for the EKS Node Group.
  subnet_ids           = data.aws_subnets.subnet-private.ids
  ami_type             = lookup(each.value, "ami_type", null) # Type of Amazon Machine Image (AMI) associated with the EKS Node Group
  disk_size            = lookup(each.value, "disk_size", null)
  instance_types       = lookup(each.value, "instance_types", null)
  release_version      = lookup(each.value, "ami_release_version", null)  # AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version.
  capacity_type        = lookup(each.value, "capacity_type", null)        # Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT
  force_update_version = lookup(each.value, "force_update_version", null) # Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
  labels               = lookup(var.node_groups[each.key], "k8s_labels", {})
  tags                 = var.resource_tags

  scaling_config {
    desired_size = each.value["desired_capacity"]
    max_size     = each.value["max_capacity"]
    min_size     = each.value["min_capacity"]
  }

  update_config {
    max_unavailable = each.value["desired_capacity"] # Desired max number of unavailable worker nodes during node group update.
  }

  dynamic "taint" {
    for_each = var.taints

    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  # lifecycle { # Optional: Allow external changes without Terraform plan difference
  #   create_before_destroy = true
  #   ignore_changes        = [scaling_config[0].desired_size]
  # }

  depends_on = [
    module.vpc,
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.WorkersIAMFullAccess,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

# Create Kubeconfig
resource "local_file" "kubeconfig" {
  content = templatefile("kubeconfig.tpl", {
    endpoint                   = aws_eks_cluster.this.endpoint
    certificate_authority_data = aws_eks_cluster.this.certificate_authority.0.data
    cluster_name               = aws_eks_cluster.this.name
  })
  filename = "${path.module}/kubeconfig.yaml"
}

# Outputs 
output "cluster_name" {
  description = "Nome do cluster Kubernetes."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint da API do cluster Kubernetes."
  value       = aws_eks_cluster.this.endpoint
}