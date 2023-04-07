# Apply IAM Root User to access EKS with AWS CLI
resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "root-aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = jsonencode([{
      userarn  = data.terraform_remote_state.eks.outputs.root_user_arn
      username = data.terraform_remote_state.eks.outputs.root_user_name
      groups   = ["system:masters"]
    }])
  }
}