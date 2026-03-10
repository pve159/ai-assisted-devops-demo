output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (one per AZ)"
  value       = aws_subnet.private[*].id
}

output "k3s_sg_id" {
  description = "Security group ID for k3s nodes"
  value       = aws_security_group.k3s.id
}

output "bastion_sg_id" {
  description = "Security group ID for the bastion"
  value       = aws_security_group.bastion.id
}
