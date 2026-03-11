data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  # Required for NAT instance: disable the source/destination check
  source_dest_check = false

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
    tags        = var.instance_tags
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/bastion-init.sh.tpl", {
    vpc_cidr    = var.vpc_cidr
    aws_region  = var.aws_region
    environment = var.environment
  })

  tags = { Name = "${var.prefix}-bastion" }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = { Name = "${var.prefix}-bastion-eip" }
}
