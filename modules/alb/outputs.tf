output "dns_name" {
  description = "ALB DNS Name"
  value = aws_lb.this.dns_name
}

output "security_group_id" {
  description = "ALB Security group ID"
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "Target group ARN"
  value = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix (CloudWatch dimesion)"
  value = aws_lb_target_group.app.arn_suffix
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix (CloudWatch dimension)"
  value = aws_lb.this.arn_suffix
}