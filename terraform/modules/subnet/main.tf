# modules/subnet/main.tf

resource "aws_subnet" "this" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.az

  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = var.subnet_name
  }
}

# 서브넷 전용 라우팅 테이블 생성
resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags = { 
    Name = "${var.subnet_name}-rt" 
  }
}

# 서브넷과 라우팅 테이블 연결 
resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

# 퍼블릭 서브넷일 때만 IGW로 가게하기
resource "aws_route" "igw_route" {
  count                  = var.map_public_ip ? 1 : 0 
  
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id # 밖에서 받아올 IGW 아이디
}

