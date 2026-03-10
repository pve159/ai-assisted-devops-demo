variable "prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used for iptables NAT masquerade rule"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID to place the bastion in"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name (needs ec2:DescribeInstances for HAProxy discovery)"
  type        = string
}

variable "instance_tags" {
  description = "Tags to apply to root EBS volumes (not covered by provider default_tags)"
  type        = map(string)
  default     = {}
}
