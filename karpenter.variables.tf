# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
variable "karpenter_namespace" {
  description = "The K8S namespace to deploy Karpenter into"
  default     = "karpenter"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.10.0"
  type        = string
}

variable "karpenter_ec2_instance_types" {
  description = "List of instance types that can be used by Karpenter"
  type        = list(string)
}

variable "karpenter_vpc_az" {
  description = "List of availability zones for the Karpenter to provision resources"
  type        = list(string)
  default     = ["sa-east-1a", "asa-east-1b", "sa-east-1c"]
}

variable "karpenter_ec2_arch" {
  description = "List of CPU architecture for the EC2 instances provisioned by Karpenter"
  type        = list(string)
  default     = ["amd64"]
}


variable "karpenter_ec2_capacity_type" {
  description = "EC2 provisioning capacity type"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "karpenter_ttl_seconds_after_empty" {
  description = "Node lifetime after empty"
  type        = number
}

variable "karpenter_ttl_seconds_until_expired" {
  description = "Node maximum lifetime"
  type        = number
}
