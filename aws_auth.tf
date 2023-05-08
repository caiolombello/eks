# Access EKS with AWS CLI
## Create IAM Root User 
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

output "root_user_name" {
  value = aws_iam_user.root-user.name
}

output "root_user_arn" {
  value = aws_iam_user.root-user.arn
}

## Create IAM Developer User

resource "aws_iam_policy" "developer" {
  name        = "developer"
  description = "Política para desenvolvedores com permissões limitadas"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "eks:Describe*",
          "eks:List*",
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user" "developer" {
  name = "developer"
}

resource "aws_iam_access_key" "developer_key" {
  user = aws_iam_user.developer.name
}

resource "aws_iam_user_policy_attachment" "developer" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.developer.arn
}

output "developer_access_key_id" {
  value     = aws_iam_access_key.developer_key.id
  sensitive = true
}

output "developer_secret_access_key" {
  value     = aws_iam_access_key.developer_key.secret
  sensitive = true
}

output "developer_name" {
  value = aws_iam_user.developer.name
}

output "developer_arn" {
  value = aws_iam_user.developer.arn
}
