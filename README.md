# Managed Kubernetes on AWS

- [x]  Deploy CloudWatch Agent for Node Memory Autoscaling
- [x] Autoscaling Nodes by CPU
- [x] Create user for AWS cluster access

## Kubernetes Configuration

To apply the IAM user for Kubernetes authentication and CloudWatch Agent:
```bash
terraform -chdir=kubernetes init
terraform -chdir=kubernetes plan
terraform -chdir=kubernetes apply
```

## Access to Cluster

Retrieve IAM data:
```bash
export aws_access_key_id=$(terraform output root_user_access_key_id)
export aws_secret_access_key=$(terraform output root_user_secret_access_key)
```

Get Kubeconfig:
```bash
aws eks update-kubeconfig --name eks-vertigo-devops-dev --region us-east-1
```