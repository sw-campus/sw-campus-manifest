
output "smtp_secret_access_key" {
  description = "IAM Secret Access Key (SMTP 비밀번호 생성용)"
  value       = aws_iam_access_key.ses_smtp.secret
  sensitive   = true
}

output "smtp_access_key_id" {
  description = "IAM Access Key ID (SMTP 사용자 이름)"
  value       = aws_iam_access_key.ses_smtp.id
  sensitive   = false
}

# 참고: SES SMTP 비밀번호는 AWS 콘솔에서 별도 생성 필요
# AWS 콘솔 → SES → SMTP Settings → Create SMTP Credentials
# 또는 AWS CLI: aws ses get-smtp-credentials --region ap-northeast-2

output "smtp_endpoint" {
  description = "SES SMTP 엔드포인트"
  value       = "email-smtp.${data.aws_region.current.name}.amazonaws.com"
}

output "smtp_port" {
  description = "SES SMTP 포트"
  value       = 587  # TLS 사용
}

output "domain_identity_arn" {
  description = "SES 도메인 인증 ARN"
  value       = aws_ses_domain_identity.main.arn
}

