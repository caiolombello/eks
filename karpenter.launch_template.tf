# Ref: https://github.com/aws-samples/karpenter-terraform/blob/main/karpenter/launch_template.tf
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}/arm64/latest/image_id"
}

# Need to create custom Launch Template to use Bottlerocket - https://github.com/aws/karpenter/issues/923
resource "aws_launch_template" "bottlerocket" {
  name = "${aws_eks_cluster.this.name}-karpenter-bottlerocket"

  image_id = data.aws_ssm_parameter.bottlerocket_ami.value

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter_node.name
  }

  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config.0.cluster_security_group_id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/bottlerocket-userdata.toml.tpl",
    {
      "cluster_endpoint"       = aws_eks_cluster.this.endpoint,
      "cluster_ca_certificate" = aws_eks_cluster.this.certificate_authority[0].data
      "cluster_name"           = aws_eks_cluster.this.name,
    }
  ))
}
