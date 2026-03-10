# IAM role for k3s masters and workers (SSM access)
resource "aws_iam_role" "k3s" {
  name = "${var.prefix}-role-k3s"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "k3s_ssm" {
  name = "${var.prefix}-policy-k3s-ssm"
  role = aws_iam_role.k3s.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:DeleteParameter"
      ]
      Resource = "arn:aws:ssm:*:*:parameter/ai-demo/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "k3s_ssm_core" {
  role       = aws_iam_role.k3s.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k3s" {
  name = "${var.prefix}-profile-k3s"
  role = aws_iam_role.k3s.name
}

# IAM role for the bastion (EC2 discovery for HAProxy dynamic config)
resource "aws_iam_role" "bastion" {
  name = "${var.prefix}-role-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_ec2_describe" {
  name = "${var.prefix}-policy-bastion-ec2"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.prefix}-profile-bastion"
  role = aws_iam_role.bastion.name
}
