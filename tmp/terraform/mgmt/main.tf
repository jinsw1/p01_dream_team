terraform {
  # 현재 terraform 버전 제한
  required_version = "~> 1.14.0"

  # 사용할 provider 정의
  required_providers {

    # AWS 리소스 생성용 provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # local-exec 같은 provisioner 사용 시 자주 함께 사용하는 provider
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # 로컬 파일(hosts.ini) 생성용 provider
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# AWS provider 설정
# 어느 리전에 리소스를 만들지 지정
provider "aws" {
  region = "ap-northeast-2"
}

# 현재 계정의 default VPC 조회
# 새 VPC를 만들지 않고 기본 VPC 재사용
data "aws_vpc" "default" {
  default = true
}

# default VPC 안 subnet 조회
# EC2 생성 시 subnet_id에 사용
data "aws_subnets" "default" {

  filter {
    name = "vpc-id"

    # 위에서 조회한 default VPC ID 사용
    values = [data.aws_vpc.default.id]
  }
}

# Amazon Linux 2023 최신 AMI 조회
# EC2 생성 시 사용할 OS 이미지
data "aws_ami" "amazon_linux" {

  # 가장 최신 이미지 사용
  most_recent = true

  # amazon 공식 AMI만 조회
  owners = ["amazon"]

  filter {
    name = "name"

    # Amazon Linux 2023 x86_64 이미지 검색
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Security Group 생성
# EC2 방화벽 역할
resource "aws_security_group" "mgmt_sg" {

  name        = "mgmt-temp-sg"
  description = "Allow SSH and HTTP"

  # 어느 VPC에 생성할지
  vpc_id = data.aws_vpc.default.id

  # SSH 허용
  ingress {

    description = "SSH"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    # 모든 IP 허용
    # 실무에서는 보통 회사 IP만 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP 허용
  ingress {

    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound 전체 허용
  # yum/apt install 인터넷 접근 등에 필요
  egress {

    description = "All outbound"

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mgmt-temp-sg"
  }
}

# EC2 생성
resource "aws_instance" "mgmt" {

  # 위에서 조회한 최신 Amazon Linux AMI 사용
  ami = data.aws_ami.amazon_linux.id

  # 프리티어 수준 인스턴스
  instance_type = "t3.micro"

  # default subnet 사용
  subnet_id = data.aws_subnets.default.ids[0]

  # 생성한 security group 연결
  vpc_security_group_ids = [
    aws_security_group.mgmt_sg.id
  ]

  # AWS에 미리 등록한 key pair 이름
  key_name = "mgmtkey"

  iam_instance_profile = aws_iam_instance_profile.mgmt_profile.name

  tags = {
    Name = "mgmt-temp-server"
  }
}

# ansible inventory 자동 생성
# terraform apply 후 hosts.ini 자동 생성됨
resource "local_file" "ansible_inventory" {

  # 생성할 파일 경로
  filename = "/mnt/e/myenv/project/ansible/mgmt.ini"

  # 파일 내용
  content = <<-EOF

# EC2 public IP 자동 삽입
# ansible_user:
#   SSH 접속 유저

# ansible_ssh_private_key_file:
#   SSH pem 키 위치
[mgmt]
${aws_instance.mgmt.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=/home/asdf/.ssh/mgmtkey.pem

EOF
}

# terraform 내부에서 ansible 실행용
resource "null_resource" "mgmt_ansible_setup" {

  # EC2 생성 후 + inventory 생성 후 실행
  depends_on = [
    aws_instance.mgmt,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {

    # bash shell 사용
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      echo "Waiting for EC2 SSH..."

      sleep 20

      until ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o ConnectionAttempts=1 \
        -i /home/asdf/.ssh/mgmtkey.pem \
        ec2-user@${aws_instance.mgmt.public_ip} \
        "echo ssh_ready" 2>/dev/null; do

        echo "SSH not ready yet..."
        sleep 10
      done

      echo "Bootstrapping.."

      cd /mnt/e/myenv/project/ansible

      ANSIBLE_CONFIG=/mnt/e/myenv/project/ansible/ansible.cfg \
      ansible-playbook site.yml
    EOT
  }
}

#################################################
# iamrole로 aws권한주기
#################################################

resource "aws_iam_role" "mgmt_role" {
  name = "mgmt-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "mgmt_admin" {
  role       = aws_iam_role.mgmt_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "mgmt_profile" {
  name = "mgmt-terraform-profile"
  role = aws_iam_role.mgmt_role.name
}

# 생성된 EC2 public IP 출력
output "public_ip" {
  value = aws_instance.mgmt.public_ip
}

# SSH 접속 명령어 출력
output "ssh_command" {

  value = "ssh -i ~/.ssh/mgmtkey.pem ec2-user@${aws_instance.mgmt.public_ip}"
}