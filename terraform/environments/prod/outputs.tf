output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = module.vpc.private_subnet_id
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = module.alb.alb_dns_name
}

output "eks_cluster_id" {
  description = "EKS 클러스터 ID"
  value       = module.eks.cluster_id
}

# RDS와 MongoDB는 EC2에 컨테이너로 배포 예정이므로 출력 제거

output "route53_zone_id" {
  description = "Route53 Zone ID"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Route53 Name Servers (도메인 등록업체에 등록해야 함)"
  value       = module.route53.name_servers
}

output "acm_certificate_arn" {
  description = "ACM Certificate ARN (자동 생성됨)"
  value       = module.route53.certificate_arn
}

# EC2 DB 출력
output "db_instance_id" {
  description = "EC2 Instance ID (PostgreSQL 컨테이너)"
  value       = module.ec2_db.instance_id
}

output "db_private_ip" {
  description = "EC2 Private IP (PostgreSQL 접속용)"
  value       = module.ec2_db.private_ip
}

# S3 출력
output "s3_private_bucket_name" {
  description = "프라이빗 버킷 이름 (재직증명서용)"
  value       = module.s3.private_bucket_name
}

output "s3_public_bucket_name" {
  description = "퍼블릭 버킷 이름"
  value       = module.s3.public_bucket_name
}

output "s3_public_bucket_domain_name" {
  description = "퍼블릭 버킷 도메인 이름 (CDN/직접 접근용)"
  value       = module.s3.public_bucket_domain_name
}

# SES 출력
output "ses_smtp_endpoint" {
  description = "SES SMTP 엔드포인트"
  value       = module.ses.smtp_endpoint
}

output "ses_smtp_port" {
  description = "SES SMTP 포트"
  value       = module.ses.smtp_port
}

output "ses_smtp_access_key_id" {
  description = "SES SMTP Access Key ID (SMTP 사용자 이름 - application-prod.yml의 MAIL_USERNAME에 입력)"
  value       = module.ses.smtp_access_key_id
}

output "ses_smtp_secret_access_key" {
  description = "IAM Secret Access Key (SMTP 비밀번호 생성용 - AWS 콘솔에서 SMTP 비밀번호 생성 필요)"
  value       = module.ses.smtp_secret_access_key
  sensitive   = true
}