## Generate PEM (and OpenSSH) formatted private key.
resource "tls_private_key" "ecs_bastion_host_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_bastion_host_key_pair" {
  key_name   = "${var.project_name}-ec2-bastion-host-key-pair-${var.env}"
  public_key = tls_private_key.ecs_bastion_host_key_pair.public_key_openssh

  tags = {
    Name = "${var.project_name}-ec2-bastion-host-key-pair-${var.env}"
  }
}

resource "aws_security_group" "ec2_bastion_sg" {
  description = "EC2 Bastion Host Security Group"
  name        = "${var.project_name}-ec2-bastion-sg-${var.env}"
  vpc_id      = var.vpc_id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # trivy:ignore:avd-aws-0107
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # trivy:ignore:avd-aws-0104
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5*-x86_64-gp2"]
  }
}

## EC2 Bastion Host
resource "aws_instance" "ec2_bastion_host" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2_bastion_host_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_bastion_sg.id]
  subnet_id                   = var.bastion_host_subnet_id
  associate_public_ip_address = false
  user_data                   = templatefile("${path.module}/userdata.tpl", {})

  root_block_device {
    volume_size           = 8
    delete_on_termination = true
    volume_type           = "gp2"
    encrypted             = true
    tags = {
      Name = "${var.project_name}-ec2-bastion-host-root-volume-${var.env}"
    }
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-ec2-bastion-host-${var.env}"
  }

  lifecycle {
    ignore_changes = [
      ami, associate_public_ip_address
    ]
  }
}

## EC2 Bastion Host Elastic IP
resource "aws_eip" "ec2_bastion_host_eip" {
  domain   = "vpc"
  instance = aws_instance.ec2_bastion_host.id

  tags = {
    Name = "${var.project_name}-ec2-bastion-host-eip-${var.env}"
  }
}