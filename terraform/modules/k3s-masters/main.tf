data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# One master per private subnet (one per AZ)
resource "aws_instance" "master" {
  count = length(var.subnet_ids)

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index]
  vpc_security_group_ids = [var.k3s_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  # Private subnet — no public IP
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/k3s-server-init.sh.tpl", {
    k3s_version = var.k3s_version
    environment = var.environment
    aws_region  = var.aws_region
    ssm_path    = "/ai-demo/${var.environment}/kubeconfig"
  })

  tags = {
    Name        = "${var.prefix}-k3s-master-${count.index + 1}"
    Role        = "k3s-master"
    environment = var.environment
  }
}
