terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group
resource "aws_security_group" "runner_sg" {
  name_prefix = "${var.project_name}-runner-"
  description = "Security group for GitHub Actions runner"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-runner-sg"
  }
}

# Key Pair
resource "aws_key_pair" "runner_key" {
  key_name   = "${var.project_name}-runner-key"
  public_key = var.public_key
}

# EC2 Instance
resource "aws_instance" "github_runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.runner_key.key_name
  vpc_security_group_ids = [aws_security_group.runner_sg.id]
  availability_zone      = data.aws_availability_zones.available.names[0]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    github_repo  = var.github_repo
    github_token = var.github_token
    runner_name  = "${var.project_name}-runner-${random_id.runner_suffix.hex}"
  }))

  tags = {
    Name = "${var.project_name}-github-runner"
    Type = "github-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "runner_suffix" {
  byte_length = 4
}