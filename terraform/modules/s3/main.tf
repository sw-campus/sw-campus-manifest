# 랜덤 suffix 생성 (버킷 이름 고유성 보장)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 프라이빗 버킷: 재직증명서용
resource "aws_s3_bucket" "private" {
  bucket = "${var.project_name}-private-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-private-bucket"
    Environment = var.environment
    Purpose     = "재직증명서 저장"
  }
}

# 프라이빗 버킷 버전 관리
resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 프라이빗 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 프라이빗 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 퍼블릭 버킷: 나머지 파일용
resource "aws_s3_bucket" "public" {
  bucket = "${var.project_name}-public-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-public-bucket"
    Environment = var.environment
    Purpose     = "일반 파일 저장"
  }
}

# 퍼블릭 버킷 버전 관리
resource "aws_s3_bucket_versioning" "public" {
  bucket = aws_s3_bucket.public.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 퍼블릭 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 버킷 정책 (읽기만 퍼블릭 허용)
resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public.arn}/*"
      }
    ]
  })
}

