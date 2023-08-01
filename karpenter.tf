# Ref: https://github.com/aws-samples/karpenter-terraform/blob/main/karpenter/karpenter.tf
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

resource "helm_release" "karpenter" {
  namespace        = var.karpenter_namespace
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh/"
  chart      = "karpenter"
  version    = var.karpenter_version


  values = [
    templatefile(
      "${path.module}/templates/values.yaml.tpl",
      {
        "karpenter_iam_role"   = module.iam_assumable_role_karpenter.iam_role_arn,
        "cluster_name"         = aws_eks_cluster.this.name,
        "cluster_endpoint"     = aws_eks_cluster.this.endpoint,
        "karpenter_node_group" = aws_eks_node_group.workers["DevOps"].node_group_name,
      }
    )
  ]
}

# A default Karpenter Provisioner manifest is created as a sample.
# Provisioner Custom Resource cannot be created at the same time as the CRD, so manifest file is created instead
# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "local_file" "karpenter_provisioner" {
  content = yamlencode({
    "apiVersion" = "karpenter.sh/v1alpha5"
    "kind"       = "Provisioner"
    "metadata" = {
      "name" = "default"
    }
    "spec" = {
      "labels" = {
        "purpose" = "demo"
      }
      "provider" = {
        "launchTemplate" = aws_launch_template.bottlerocket.name
        "subnetSelector" = {
          format("kubernetes.io/cluster/%s", aws_eks_cluster.this.name) = "true"
        }
        "securityGroupSelector" = {
          format("kubernetes.io/cluster/%s", aws_eks_cluster.this.name) = "owned"
        }
      }
      "requirements" = [
        {
          "key"      = "node.kubernetes.io/instance-type"
          "operator" = "In"
          "values"   = "${var.node_groups["DevOps"]["instance_types"][0]}"
        },
        {
          "key"      = "topology.kubernetes.io/zone"
          "operator" = "In"
          "values"   = "${var.karpenter_vpc_az}"
        },
        {
          "key"      = "kubernetes.io/arch"
          "operator" = "In"
          "values"   = "${var.karpenter_ec2_arch}"
        },
        {
          "key"      = "karpenter.sh/capacity-type"
          "operator" = "In"
          "values"   = "${var.node_groups["DevOps"]["capacity_type"]}"
        },
      ]
      "ttlSecondsAfterEmpty"   = "${var.karpenter_ttl_seconds_after_empty}"
      "ttlSecondsUntilExpired" = "${var.karpenter_ttl_seconds_until_expired}" # 7 days
    }
  })

  filename = "${path.module}/default-provisioner.yaml"
}
