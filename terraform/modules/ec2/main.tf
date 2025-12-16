# Amazon Linux 2023 AMI 자동 선택
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2 (PostgreSQL)
resource "aws_security_group" "db_ec2" {
  name        = "${var.project_name}-db-ec2-sg"
  description = "Security group for EC2 running PostgreSQL container"
  vpc_id      = var.vpc_id

  # PostgreSQL 포트 (EKS에서만 접근 가능)
  ingress {
    description     = "PostgreSQL from VPC"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]  # VPC 내부에서만 접근 가능
  }

  # SSH 접근 (관리용, 필요시 제한)
  ingress {
    description     = "SSH from VPC"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]  # VPC 내부에서만 SSH 가능
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-ec2-sg"
  }
}

# EC2 Instance for PostgreSQL
resource "aws_instance" "db" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id  # Private Subnet
  vpc_security_group_ids = [aws_security_group.db_ec2.id]
  
  # 스토리지는 S3 사용하므로 EBS는 최소 크기
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # User Data: Docker 설치 및 PostgreSQL 컨테이너 실행
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              
              # Docker 설치
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Docker Compose 설치
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # 볼륨 먼저 생성
              docker volume create postgres_data
              
              # PostgreSQL 컨테이너 실행
              docker run -d \
                --name sw-campus-postgres \
                --restart unless-stopped \
                -e POSTGRES_DB=${var.postgres_db} \
                -e POSTGRES_USER=${var.postgres_user} \
                -e POSTGRES_PASSWORD=${var.postgres_password} \
                -p 5432:5432 \
                -v postgres_data:/var/lib/postgresql/data \
                postgres:16
              
              # 로그 확인용
              echo "PostgreSQL container started" >> /var/log/user-data.log
              EOF

  tags = {
    Name = "${var.project_name}-db-ec2"
  }
}

