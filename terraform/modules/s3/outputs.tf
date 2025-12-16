output "private_bucket_name" {
  description = "프라이빗 버킷 이름 (재직증명서용)"
  value       = aws_s3_bucket.private.id
}

output "private_bucket_arn" {
  description = "프라이빗 버킷 ARN"
  value       = aws_s3_bucket.private.arn
}

output "public_bucket_name" {
  description = "퍼블릭 버킷 이름"
  value       = aws_s3_bucket.public.id
}

output "public_bucket_arn" {
  description = "퍼블릭 버킷 ARN"
  value       = aws_s3_bucket.public.arn
}

output "public_bucket_domain_name" {
  description = "퍼블릭 버킷 도메인 이름 (CDN/직접 접근용)"
  value       = aws_s3_bucket.public.bucket_domain_name
}

