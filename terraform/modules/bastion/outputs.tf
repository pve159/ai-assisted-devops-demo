output "public_ip" {
  description = "Bastion public IP (Elastic IP)"
  value       = aws_eip.bastion.public_ip
}

output "instance_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "network_interface_id" {
  description = "Primary ENI ID — used as NAT target in private route tables"
  value       = aws_instance.bastion.primary_network_interface_id
}

