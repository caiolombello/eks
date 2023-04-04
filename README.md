# Managed Kubernetes on AWS

- [x] Autoscaling por Memória dos Nodes
- [x] Autoscaling por CPU dos Nodes
- [x] Criação de usuário para acesso ao Cluster através da AWS

## Access Cluster

Retrieve generated IAM data:
```bash
export aws_access_key_id=$(terraform output root_user_access_key_id)
export aws_secret_access_key=$(terraform output root_user_secret_access_key)
```

Get Kubeconfig:
```bash
aws eks update-kubeconfig --name eks-vertigo-devops-dev --region us-east-1
```