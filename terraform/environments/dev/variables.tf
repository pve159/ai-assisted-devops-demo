variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR block for the bastion public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones (same length as private_subnet_cidrs)"
  type        = list(string)
  default     = ["eu-west-3b", "eu-west-3c"]
}

variable "master_instance_type" {
  description = "EC2 instance type for k3s master"
  type        = string
  default     = "t4g.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for k3s workers"
  type        = string
  default     = "t4g.micro"
}

variable "workers_per_subnet" {
  description = "Number of worker nodes per private subnet"
  type        = number
  default     = 2
}

variable "k3s_version" {
  description = "k3s version to install"
  type        = string
  default     = "v1.29.0+k3s1"
}
