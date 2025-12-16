variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes 버전"
  type        = string
  default     = "1.28"
}

variable "node_desired_size" {
  description = "원하는 노드 수"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "최대 노드 수"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "최소 노드 수"
  type        = number
  default     = 1
}

variable "node_instance_type" {
  description = "노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

