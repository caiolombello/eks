locals {
  name_suffix = var.resource_tags["Name"]
  environment = var.resource_tags["Environment"]

  # IAM
  iam_cluster_role_name        = var.iam_cluster_role_name != "" ? var.iam_cluster_role_name : null
  iam_cluster_role_name_prefix = var.iam_cluster_role_name != "" ? null : local.name_suffix
  iam_workers_role_name        = var.iam_workers_role_name != "" ? var.iam_workers_role_name : null
  iam_workers_role_name_prefix = var.iam_workers_role_name != "" ? null : local.name_suffix

  # Node groups
  node_groups_expanded = { for k, v in var.node_groups : k => merge(
    {
      desired_capacity = 4
      max_capacity     = 6
      min_capacity     = 4
    }, v)
  }

  # Schedule
  today_date    = formatdate("YYYY-MM-DD", timestamp())                 # Data atual
  tomorrow_date = formatdate("YYYY-MM-DD", timeadd(timestamp(), "24h")) # Data de amanhã
}
