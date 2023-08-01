# Schedule
# resource "aws_autoscaling_schedule" "monrise" {
#   for_each               = var.node_groups
#   scheduled_action_name  = "monrise"
#   min_size               = 0
#   max_size               = 0
#   desired_capacity       = 0
#   recurrence             = "0 19 * * MON-FRI"
#   start_time             = "${local.today_date}T21:00:00Z" #UTC time
#   time_zone              = "America/Sao_Paulo"
#   autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name

#   depends_on = [
#     aws_eks_node_group.workers
#   ]
# }

# resource "aws_autoscaling_schedule" "sunrise" {
#   for_each               = var.node_groups
#   scheduled_action_name  = "sunrise"
#   min_size               = aws_eks_node_group.workers[each.key].scaling_config[0].min_size
#   max_size               = aws_eks_node_group.workers[each.key].scaling_config[0].max_size
#   desired_capacity       = aws_eks_node_group.workers[each.key].scaling_config[0].desired_size
#   recurrence             = "0 7 * * MON-FRI"
#   start_time             = "${local.tomorrow_date}T12:00:00Z" #UTC time
#   time_zone              = "America/Sao_Paulo"
#   autoscaling_group_name = aws_eks_node_group.workers[each.key].resources[0].autoscaling_groups[0].name

#   depends_on = [
#     aws_eks_node_group.workers
#   ]
# }

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
resource "aws_cloudwatch_metric_alarm" "node_memory_utilization_alarm" {
  for_each = toset(var.scaling_period)

  alarm_name          = "node_memory_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1" #O número de períodos durante os quais os dados são comparados com o limite especificado.
  threshold           = "80"
  alarm_description   = "This metric checks for memory usage above 80%"
  alarm_actions       = [aws_autoscaling_policy.memory_scale_up_policy[each.key].arn]
  ok_actions          = [aws_autoscaling_policy.memory_scale_down_policy[each.key].arn]

  period      = 60
  metric_name = "node_memory_utilization"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = "${aws_eks_cluster.this.name}"
  }
  statistic = "Average"

  datapoints_to_alarm = "1"

  depends_on = [
    aws_eks_node_group.workers
  ]
}


# Autoscaling Policies
resource "aws_autoscaling_policy" "memory_scale_up_policy" {
  for_each               = toset(var.scaling_period)
  name                   = "${each.key}-memory-scale-up-policy"
  autoscaling_group_name = aws_eks_node_group.workers["DevOps"].resources[0].autoscaling_groups[0].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = each.key

  depends_on = [
    aws_eks_node_group.workers
  ]
}

resource "aws_autoscaling_policy" "memory_scale_down_policy" {
  for_each               = toset(var.scaling_period)
  name                   = "${each.key}-memory-scale-down-policy"
  autoscaling_group_name = aws_eks_node_group.workers["DevOps"].resources[0].autoscaling_groups[0].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = each.key

  depends_on = [
    aws_eks_node_group.workers
  ]
}