variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "subnet_id" {
  description = "EC2를 배치할 서브넷 ID (Private Subnet 권장)"
  type        = string
}

variable "ami_id" {
  description = "EC2 AMI ID (Amazon Linux 2023)"
  type        = string
  default     = ""  # 리전별로 자동 선택
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
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
  description = "PostgreSQL 비밀번호"
  type        = string
  sensitive   = true
}

