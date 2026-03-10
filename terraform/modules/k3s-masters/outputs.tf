output "instance_ids" {
  description = "k3s master instance IDs"
  value       = aws_instance.master[*].id
}

output "private_ips" {
  description = "k3s master private IPs (one per AZ)"
  value       = aws_instance.master[*].private_ip
}
