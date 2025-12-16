output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.db.id
}

output "private_ip" {
  description = "EC2 Private IP (PostgreSQL 접속용)"
  value       = aws_instance.db.private_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.db_ec2.id
}

