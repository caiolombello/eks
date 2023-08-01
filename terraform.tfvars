aws_region = "us-east-1"

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

karpenter_namespace = "karpenter"
karpenter_version   = "v0.10.0"

# The variables below are used for the default Karpenter Provisioner that is deployed in this script
karpenter_ec2_instance_types = [
  "m7g.medium",
  "m7g.large",
  "m7g.xlarge",
  "m7g.2xlarge",
  "m7g.4xlarge",
  "m7g.8xlarge",
  "m7g.12xlarge",
  "m7g.16xlarge",
]
karpenter_vpc_az = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c",
]
karpenter_ec2_arch                  = ["arm64"]
karpenter_ec2_capacity_type         = ["spot", "on-demand"]
karpenter_ttl_seconds_after_empty   = 300
karpenter_ttl_seconds_until_expired = 604800
