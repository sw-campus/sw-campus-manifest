output "zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Route53 Name Servers"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ACM Certificate ARN (검증 완료 후)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

