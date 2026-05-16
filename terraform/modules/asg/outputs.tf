# modules/asg/outputs.tf

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}