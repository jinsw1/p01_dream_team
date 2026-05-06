# modules/security-group/main.tf

resource "aws_security_group" "this" {
  name   = var.sg_name
  vpc_id = var.vpc_id

  # 포트 리스트(ingress_ports)받아서 리스트만큼 반복하여 규칙을 만든다
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # 일단 전체 접근 허용
    }
  }
  
  # 안에서 밖으로 나가는 규칙 (기본적으로 모두 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}