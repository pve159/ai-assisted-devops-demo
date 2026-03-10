output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP)"
  value       = module.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID — used to open SSM sessions"
  value       = module.bastion.instance_id
}

output "master_instance_ids" {
  description = "k3s master EC2 instance IDs — used to open SSM sessions"
  value       = module.k3s_masters.instance_ids
}

output "k3s_master_private_ips" {
  description = "Private IPs of all k3s masters (one per AZ)"
  value       = module.k3s_masters.private_ips
}

output "workers_asg_name" {
  description = "Workers Auto Scaling Group name"
  value       = module.k3s_workers.asg_name
}
