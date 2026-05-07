# terraform/was/main.tf

terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source = "hashicorp/tls"
    }

    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "tls_private_key" "was_key" { # key 생성
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "was_keypair" {
  key_name   = "tmp_was"
  public_key = tls_private_key.was_key.public_key_openssh
}

resource "local_file" "was_pem" {
  filename        = "/home/ec2-user/.ssh/tmp_was.pem"
  content         = tls_private_key.was_key.private_key_pem
  file_permission = "0600"
}

resource "aws_security_group" "was_sg" {
  name   = "tmp-was-sg"
  vpc_id = data.aws_vpc.main.id

  ingress {
    description = "SSH 22"
    from_port   = 22
    to_port     = 22
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
    Name = "tmp-was-sg"
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "was" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnets.public_subnets.ids[0]

  vpc_security_group_ids = [
    aws_security_group.was_sg.id
  ]

  key_name = aws_key_pair.was_keypair.key_name

  tags = {
    Name = "tmp-was"
  }
}

resource "local_file" "ansible_inventory" {

  # 생성할 파일 경로
  filename = "/home/ec2-user/was/ansible/was.ini"

  # 파일 내용
  content = <<-EOF

# EC2 public IP 자동 삽입
# ansible_user:
#   SSH 접속 유저

# ansible_ssh_private_key_file:
#   SSH pem 키 위치
[was]
${aws_instance.was.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/.ssh/tmp_was.pem

EOF
}

resource "null_resource" "was_ansible_setup" {
  depends_on = [
    aws_instance.was,
    local_file.was_pem,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      echo "Waiting for WAS SSH..."

      sleep 20

      until ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o ConnectionAttempts=1 \
        -i /home/ec2-user/.ssh/tmp_was.pem \
        ec2-user@${aws_instance.was.private_ip} \
        "echo ssh_ready" 2>/dev/null; do

        echo "WAS SSH not ready yet..."
        sleep 10
      done

      echo "Running WAS Ansible..."

      cd /home/ec2-user/was/ansible

      ANSIBLE_CONFIG=/home/ec2-user/was/ansible/ansible.cfg \
      ansible-playbook site.yml
    EOT
  }
}

output "pem_file" {
  value = local_file.was_pem.filename
}

output "was_private_ip" {
  value = aws_instance.was.private_ip
}