variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "Public Subnet 2 CIDR (ALB는 최소 2개 서브넷 필요)"
  type        = string
  default     = "10.0.1.128/25"
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zones" {
  description = "가용 영역 리스트"
  type        = list(string)
}

