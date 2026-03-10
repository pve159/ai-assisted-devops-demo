module "network" {
  source = "../network"

  prefix               = var.prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "bastion" {
  source = "../bastion"

  prefix               = var.prefix
  environment          = var.environment
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  subnet_id            = module.network.public_subnet_ids[0]
  bastion_sg_id        = module.network.bastion_sg_id
  iam_instance_profile = aws_iam_instance_profile.bastion.name
}

# Private route tables: one per private subnet, default route via bastion ENI (NAT)
resource "aws_route_table" "private" {
  count  = length(module.network.private_subnet_ids)
  vpc_id = module.network.vpc_id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bastion.network_interface_id
  }

  tags = { Name = "${var.prefix}-rt-private-${count.index + 1}" }
}

resource "aws_route_table_association" "private" {
  count          = length(module.network.private_subnet_ids)
  subnet_id      = module.network.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

module "k3s_masters" {
  source = "../k3s-masters"

  prefix               = var.prefix
  environment          = var.environment
  aws_region           = var.aws_region
  instance_type        = var.master_instance_type
  subnet_ids           = module.network.private_subnet_ids
  k3s_sg_id            = module.network.k3s_sg_id
  iam_instance_profile = aws_iam_instance_profile.k3s.name
  root_volume_size     = var.master_volume_size
  k3s_version          = var.k3s_version

  depends_on = [aws_route_table_association.private]
}

module "k3s_workers" {
  source = "../k3s-workers"

  prefix               = var.prefix
  environment          = var.environment
  instance_type        = var.worker_instance_type
  workers_per_subnet   = var.workers_per_subnet
  subnet_ids           = module.network.private_subnet_ids
  k3s_sg_id            = module.network.k3s_sg_id
  iam_instance_profile = aws_iam_instance_profile.k3s.name
  master_private_ip    = module.k3s_masters.private_ips[0]
  root_volume_size     = var.worker_volume_size
  k3s_version          = var.k3s_version

  depends_on = [aws_route_table_association.private]
}
