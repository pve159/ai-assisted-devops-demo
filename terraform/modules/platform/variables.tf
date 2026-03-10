variable "prefix" {
  description = "Resource name prefix (e.g. ai-demo-dev)"
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
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one subnet for the bastion)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ, same order)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones (same length as subnet lists)"
  type        = list(string)
}

variable "master_instance_type" {
  description = "EC2 instance type for k3s masters"
  type        = string
  default     = "t3.medium"
}

variable "master_volume_size" {
  description = "Root volume size for k3s masters (GB)"
  type        = number
  default     = 30
}

variable "worker_instance_type" {
  description = "EC2 instance type for k3s workers"
  type        = string
  default     = "t3.medium"
}

variable "workers_per_subnet" {
  description = "Number of worker nodes per private subnet (0 to disable)"
  type        = number
  default     = 0
}

variable "worker_volume_size" {
  description = "Root volume size for k3s workers (GB)"
  type        = number
  default     = 20
}

variable "k3s_version" {
  description = "k3s version to install"
  type        = string
  default     = "v1.29.0+k3s1"
}
