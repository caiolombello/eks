# Create IAM Root User to access EKS with AWS CLI
resource "aws_iam_user" "root-user" {
  name = "root-user"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.workers
  ]
}

resource "aws_iam_access_key" "root-user_key" {
  user = aws_iam_user.root-user.name

  depends_on = [
    aws_iam_user.root-user
  ]
}

output "root_user_access_key_id" {
  value     = aws_iam_access_key.root-user_key.id
  sensitive = true
}

output "root_user_secret_access_key" {
  value     = aws_iam_access_key.root-user_key.secret
  sensitive = true
}

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.workers,
    data.local_file.kubeconfig
  ]

  metadata {
    name      = "root-aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = jsonencode([{
      userarn  = aws_iam_user.root-user.arn
      username = aws_iam_user.root-user.name
      groups   = ["system:masters"]
    }])
  }
}