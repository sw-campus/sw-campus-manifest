variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "domain_name" {
  description = "도메인 이름 (예: softwarecampus.co.kr)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

