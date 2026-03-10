locals {
  env        = "dev"
  bastion_id = module.platform.bastion_instance_id
  bastion_ip = module.platform.bastion_public_ip
  master_ids = module.platform.master_instance_ids
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP)"
  value       = local.bastion_ip
}

output "ssm_connect_bastion" {
  description = "Open an interactive shell on the bastion via SSM"
  value       = "aws ssm start-session --target ${local.bastion_id} --region eu-west-3"
}

output "ssm_connect_masters" {
  description = "Open an interactive shell on each k3s master via SSM"
  value       = { for idx, id in local.master_ids : "master-${idx + 1}" => "aws ssm start-session --target ${id} --region eu-west-3" }
}

output "ssm_kubectl_tunnel" {
  description = "Forward port 6443 via SSM to reach the k3s API through HAProxy on the bastion"
  value       = "aws ssm start-session --target ${local.bastion_id} --region eu-west-3 --document-name AWS-StartPortForwardingSession --parameters '{\"localPortNumber\":[\"6443\"],\"portNumber\":[\"6443\"]}'"
}

output "kubeconfig_command" {
  description = "Fetch kubeconfig from SSM Parameter Store (run after opening the tunnel above)"
  value       = <<-CMD
    aws ssm get-parameter \
      --name "/ai-demo/${local.env}/kubeconfig" \
      --with-decryption \
      --query "Parameter.Value" \
      --output text \
      | sed 's|server: https://[^:]*:|server: https://127.0.0.1:|' \
      > ~/.kube/ai-demo-${local.env}
    export KUBECONFIG=~/.kube/ai-demo-${local.env}
  CMD
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.platform.vpc_id
}
