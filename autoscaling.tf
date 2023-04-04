# Schedule
resource "aws_autoscaling_schedule" "monrise" {
  for_each               = var.node_groups
  scheduled_action_name  = "monrise"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * MON-FRI"
  start_time             = "${local.today_date}T21:00:00Z" #UTC time
  time_zone              = "America/Sao_Paulo"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
}

resource "aws_autoscaling_schedule" "sunrise" {
  for_each               = var.node_groups
  scheduled_action_name  = "sunrise"
  min_size               = aws_eks_node_group.workers[each.key].scaling_config[0].min_size
  max_size               = aws_eks_node_group.workers[each.key].scaling_config[0].max_size
  desired_capacity       = aws_eks_node_group.workers[each.key].scaling_config[0].desired_size
  recurrence             = "0 7 * * MON-FRI"
  start_time             = "${local.tomorrow_date}T12:00:00Z" #UTC time
  time_zone              = "America/Sao_Paulo"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
}

# Set up the CloudWatch agent to collect cluster metrics
resource "null_resource" "apply-cloudwatch-agent" {
  for_each = toset(local.manifests_urls)

  provisioner "local-exec" {
    command = format("kubectl apply -f %s",
      each.value
    )
  }
}

resource "null_resource" "apply-cloudwatch-agent-config" {
  provisioner "local-exec" {
    command = format("kubectl apply -f - <<EOF\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: cwagentconfig\n  namespace: amazon-cloudwatch\ndata:\n  cwagentconfig.json: |\n    %s\nEOF",
      jsonencode({
        "logs" : {
          "metrics_collected" : {
            "kubernetes" : {
              "cluster_name" : aws_eks_cluster.this.name,
              "metrics_collection_interval" : 60
            }
          },
          "force_flush_interval" : 5
        }
      })
    )
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.workers
  ]
}


# CPU Autoscale
resource "aws_autoscaling_policy" "cpu_scale_up_policy" {
  for_each               = var.node_groups
  name                   = "cpu_scale_up_policy"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 80.0
  }

  depends_on = [
    aws_eks_node_group.workers
  ]
}

# Memory Autoscale
# Memory Alarm
resource "aws_cloudwatch_metric_alarm" "node_memory_utilization_alarm" {
  for_each = var.node_groups

  alarm_name          = "node_memory_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "80"
  alarm_description   = "This metric checks for memory usage above 80%"
  alarm_actions       = [aws_autoscaling_policy.memory_scale_up_policy[each.key].arn]
  ok_actions          = [aws_autoscaling_policy.memory_scale_down_policy[each.key].arn]

  period      = 300
  metric_name = "node_memory_utilization"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = "${aws_eks_cluster.this.name}"
  }
  statistic = "Average"

  datapoints_to_alarm = "1"
}


# Autoscaling Policies
resource "aws_autoscaling_policy" "memory_scale_up_policy" {
  for_each               = var.node_groups
  name                   = "${each.key}-memory-scale-up-policy"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300

  depends_on = [
    aws_eks_node_group.workers
  ]
}

resource "aws_autoscaling_policy" "memory_scale_down_policy" {
  for_each               = var.node_groups
  name                   = "${each.key}-memory-scale-down-policy"
  autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300

  depends_on = [
    aws_eks_node_group.workers
  ]
}