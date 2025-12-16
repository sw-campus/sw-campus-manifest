terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # 상태 파일 저장 위치 (나중에 S3로 변경 가능)
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
  
  default_tags {
    tags = {
      Project     = "sw-campus"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Route53 Module (ALB보다 먼저 생성되어야 인증서 ARN을 받을 수 있음)
module "route53" {
  source = "../../modules/route53"

  project_name = var.project_name
  domain_name  = var.domain_name
}

# SES Module (이메일 인증용)
module "ses" {
  source = "../../modules/ses"

  project_name     = var.project_name
  domain_name      = var.domain_name
  route53_zone_id  = module.route53.zone_id

  depends_on = [module.route53]
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids  # ALB는 최소 2개 서브넷 필요
  certificate_arn   = module.route53.certificate_arn  # Route53 모듈에서 자동 생성된 인증서 ARN 사용
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_id  = module.vpc.private_subnet_id
  kubernetes_version = "1.28"
  node_desired_size  = 2
  node_max_size      = 4
  node_min_size      = 1
  node_instance_type = "t3.medium"
}

# EC2 Module (PostgreSQL 컨테이너)
module "ec2_db" {
  source = "../../modules/ec2"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  subnet_id         = module.vpc.private_subnet_id  # Private Subnet에 배치
  instance_type     = var.db_instance_type
  postgres_db       = var.postgres_db
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
}

# S3 Module (프라이빗 + 퍼블릭 버킷)
module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# Route53 Module의 ALB 레코드 업데이트 (ALB 생성 후)
resource "aws_route53_record" "alb" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }

  depends_on = [module.alb]
}