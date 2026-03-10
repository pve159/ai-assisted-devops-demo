data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "worker" {
  name_prefix   = "${var.prefix}-k3s-worker-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    # Private subnet — no public IP
    associate_public_ip_address = false
    security_groups             = [var.k3s_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/k3s-agent-init.sh.tpl", {
    k3s_version = var.k3s_version
    k3s_url     = "https://${var.master_private_ip}:6443"
    k3s_token   = var.k3s_token
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.prefix}-k3s-worker"
      Role        = "k3s-worker"
      environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "workers" {
  name = "${var.prefix}-k3s-workers-asg"

  # Total workers = workers_per_subnet × number of private subnets
  desired_capacity    = var.workers_per_subnet * length(var.subnet_ids)
  min_size            = 0
  max_size            = (var.workers_per_subnet + 1) * length(var.subnet_ids)
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-k3s-worker"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
