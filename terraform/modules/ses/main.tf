# 현재 리전 정보
data "aws_region" "current" {}

# SES 도메인 인증 (softwarecampus.co.kr)
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

# SES 도메인 인증 확인을 위한 Route53 레코드
resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# SES 도메인 DKIM 인증
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# SES 도메인 DKIM 확인을 위한 Route53 레코드 (3개)
resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# SES 이메일 주소 인증 (선택사항 - 도메인 인증만으로도 충분)
# resource "aws_ses_email_identity" "noreply" {
#   email = "noreply@${var.domain_name}"
# }

# SES 구성 집합 (전송 통계 추적)
resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-ses-config"
}

# SES 구성 집합 이벤트 대상 (CloudWatch)
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "${var.project_name}-cloudwatch"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery", "open", "click", "renderingFailure"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# IAM 사용자 (SES SMTP 접근용)
resource "aws_iam_user" "ses_smtp" {
  name = "${var.project_name}-ses-smtp-user"
  path = "/"
}

# IAM 액세스 키 (SMTP 인증용)
resource "aws_iam_access_key" "ses_smtp" {
  user = aws_iam_user.ses_smtp.name
}

# SES 전송 권한 정책
resource "aws_iam_user_policy" "ses_send" {
  name = "${var.project_name}-ses-send-policy"
  user = aws_iam_user.ses_smtp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# 프로덕션 환경으로 승격 (Sandbox 해제)
# 주의: AWS Support에 요청해야 함 (자동 승인 안 됨)
# resource "aws_ses_account_sending_enabled" "main" {
#   enabled = true
# }

