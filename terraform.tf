# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Lookup the default VPC and its subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Choose the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 1) Create an EC2 Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-lt-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t3.micro"

  # (Optional) Security group, key pair, etc.
  # vpc_security_group_ids = [aws_security_group.sg.id]
  # key_name               = var.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "example-instance"
    }
  }
}

# 2) Create an Auto Scaling Group that uses the above Launch Template
resource "aws_autoscaling_group" "example" {
  name_prefix          = "example-asg-"
  max_size             = 2
  min_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  # THIS BLOCK satisfies the Kyverno policy
  launch_template {
    id      = aws_launch_template.example.id
    # You can specify a version number or use "$Latest" / "$Default"
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "example-asg-instance"
    propagate_at_launch = true
  }

  # (Optional) health checks, scaling policies, etc.
  # health_check_type         = "EC2"
  # health_check_grace_period = 300
}
