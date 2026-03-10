locals {
  prefix      = "ai-demo-dev"
  environment = "dev"

  # Tags applied everywhere: via provider default_tags (most resources)
  # and explicitly via instance_tags (ASG tag blocks + launch template tag_specifications)
  instance_tags = {
    Environment = "Dev"
    Service     = "k3s-platform"
    Owner       = "platform-team"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({ Project = "ai-demo", ManagedBy = "terraform" }, local.instance_tags)
  }
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
  instance_tags        = local.instance_tags
}
