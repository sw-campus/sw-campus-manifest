variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "sw-campus"
}

variable "environment" {
  description = "환경 이름"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역"
  type        = list(string)
  default     = ["ap-northeast-2a"]  # AZ A만 사용
}

variable "domain_name" {
  description = "도메인 이름 (예: softwarecampus.co.kr) - Route53 Hosted Zone 생성에 사용"
  type        = string
}

variable "db_instance_type" {
  description = "EC2 인스턴스 타입 (PostgreSQL 컨테이너용)"
  type        = string
  default     = "t3.medium"
}

variable "postgres_db" {
  description = "PostgreSQL 데이터베이스 이름"
  type        = string
  default     = "swcampus"
}

variable "postgres_user" {
  description = "PostgreSQL 사용자 이름"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL 비밀번호 (민감 정보)"
  type        = string
  sensitive   = true
}
