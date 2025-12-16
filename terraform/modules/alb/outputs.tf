output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "server_target_group_arn" {
  description = "Server Target Group ARN"
  value       = aws_lb_target_group.server.arn
}

output "client_target_group_arn" {
  description = "Client Target Group ARN"
  value       = aws_lb_target_group.client.arn
}

