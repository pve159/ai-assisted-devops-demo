provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ai-demo"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "platform-team"
    }
  }
}

locals {
  prefix      = "ai-demo-dev"
  environment = "dev"
}

module "platform" {
  source = "../../modules/platform"

  prefix               = local.prefix
  environment          = local.environment
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  master_instance_type = var.master_instance_type
  master_volume_size   = 30
  worker_instance_type = var.worker_instance_type
  workers_per_subnet   = var.workers_per_subnet
  worker_volume_size   = 20
  k3s_version          = var.k3s_version
}
