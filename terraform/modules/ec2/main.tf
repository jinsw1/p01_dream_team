# modules/ec2/main.tf

# 최신 Amazon Linux 2023
data "aws_ami" "latest_al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "this" {
  ami                    = data.aws_ami.latest_al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.sg_ids # 리스트 형태
  key_name               = var.key_name

  tags = {
    Name = var.name
  }
}