terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "demo_sg_web" {
  name        = "demo-sg-web"
  description = "SSH from my IP, HTTP open"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg-web"
  }
}

resource "aws_instance" "demo_web_01" {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y || apt update -y
    echo "Miao Janice" > /var/log/miao-janice.log
    echo "Miao Janice" | tee /etc/motd
    if command -v yum >/dev/null 2>&1; then
      yum install -y nginx
    else
      apt install -y nginx
    fi
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Miao da Janice 🐱</h1>" > /usr/share/nginx/html/index.html
  EOF

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.demo_sg_web.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "demo-web-01"
  }
}
