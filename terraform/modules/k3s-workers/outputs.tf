output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.workers.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.worker.id
}
