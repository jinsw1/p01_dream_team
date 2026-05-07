############################################
# 1. DATA SOURCE (가용 AZ 조회)
############################################
# AWS가 제공하는 사용 가능한 AZ 목록을 가져옴
# → subnet을 여러 AZ에 분산 배치하기 위해 사용
data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# 2. NETWORK LAYER (VPC / IGW / SUBNET)
############################################

# VPC 생성
# → 모든 네트워크 리소스의 최상위 컨테이너
module "project01_vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "project01-vpc"
}

# Internet Gateway 생성
# → VPC 내부에서 인터넷으로 나가는 출구 역할
module "igw" {
  source  = "../../modules/internet-gateway"
  vpc_id  = module.project01_vpc.vpc_id
  name    = "project01-igw"
}

# Bastion Subnet (Public)
# → 관리자 접속용 서버가 위치하는 퍼블릭 서브넷
module "project01_public_subnet_bastion" {
  source         = "../../modules/subnet"
  vpc_id         = module.project01_vpc.vpc_id
  cidr_block     = "10.0.1.0/24"
  az             = data.aws_availability_zones.available.names[0]
  map_public_ip  = true
  name           = "project01-public-subnet-bastion"
}

# ALB Public Subnet (A/B)
# → 로드밸런서가 외부 요청을 받는 퍼블릭 서브넷
# → AZ 분산으로 장애 대비 (HA 구성)
module "project01_public_subnet_alb_a" {
  source         = "../../modules/subnet"
  vpc_id         = module.project01_vpc.vpc_id
  cidr_block     = "10.0.2.0/24"
  az             = data.aws_availability_zones.available.names[0]
  map_public_ip  = true
  name           = "project01-public-subnet-alb-a"
}

module "project01_public_subnet_alb_b" {
  source         = "../../modules/subnet"
  vpc_id         = module.project01_vpc.vpc_id
  cidr_block     = "10.0.3.0/24"
  az             = data.aws_availability_zones.available.names[1]
  map_public_ip  = true
  name           = "project01-public-subnet-alb-b"
}

# WAS Private Subnet
# → 실제 애플리케이션 서버가 위치 (외부 직접 접근 불가)
module "project01_private_subnet_was" {
  source         = "../../modules/subnet"
  vpc_id         = module.project01_vpc.vpc_id
  cidr_block     = "10.0.10.0/24"
  az             = data.aws_availability_zones.available.names[0]
  map_public_ip  = false
  name           = "project01-private-subnet-was"
}

# DB Private Subnet
# → 데이터베이스 전용 (외부 완전 차단)
module "project01_private_subnet_db" {
  source         = "../../modules/subnet"
  vpc_id         = module.project01_vpc.vpc_id
  cidr_block     = "10.0.30.0/24"
  az             = data.aws_availability_zones.available.names[0]
  map_public_ip  = false
  name           = "project01-private-subnet-db"
}

############################################
# 3. ROUTING LAYER (라우팅 테이블)
############################################

# Public Route Table
# → 0.0.0.0/0 트래픽을 IGW로 보내 인터넷 연결 허용
resource "aws_route_table" "project01_public_rt" {
  vpc_id = module.project01_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.igw.igw_id
  }

  tags = {
    Name = "project01-public-rt"
  }
}

# Public Subnet 연결
# → 해당 subnet을 인터넷 가능한 라우팅 테이블에 연결
resource "aws_route_table_association" "bastion_rt" {
  subnet_id      = module.project01_public_subnet_bastion.subnet_id
  route_table_id = aws_route_table.project01_public_rt.id
}

# NAT Gateway
# → Private subnet이 인터넷 outbound 가능하도록 중계 역할
module "project01_ngw" {
  source    = "../../modules/nat-gateway"
  subnet_id = module.project01_public_subnet_bastion.subnet_id
  name      = "project01-ngw"
}

# Private Route Table
# → private subnet의 인터넷 outbound를 NAT로 보냄
resource "aws_route_table" "project01_private_rt" {
  vpc_id = module.project01_vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = module.project01_ngw.nat_gateway_id
  }

  depends_on = [module.project01_ngw]

  tags = {
    Name = "project01-private-rt"
  }
}

############################################
# 4. SECURITY GROUP (방화벽 역할)
############################################
# Bastion SG
# → 외부에서 SSH 접속 허용 (관리용)
module "project01_bastion_sg" {
  source = "../../modules/security-group"
  name   = "project01-bastion-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "관리자 SSH 접근"
    }
  ]
}

# WAS SG
# → ALB만 WAS 접근 가능
# → Bastion만 SSH 접근 가능
module "project01_was_sg" {
  source = "../../modules/security-group"
  name   = "project01-was-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.project01_bastion_sg.sg_id]
      description     = "Bastion에서 SSH"
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.project01_alb_sg.sg_id]
      description     = "ALB → WAS HTTP"
    }
  ]
}

# DB SG
# → WAS만 DB 접근 가능 (3-tier 구조 핵심)
module "project01_db_sg" {
  source = "../../modules/security-group"
  name   = "project01-db-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [module.project01_was_sg.sg_id]
      description     = "WAS → DB 접근"
    }
  ]
}

############################################
# 5. COMPUTE (EC2)
############################################

# Bastion Server
# → 운영자가 SSH로 접속하는 유일한 entry point
module "project01_bastion_ec2" {
  source = "../../modules/ec2"
  subnet_id          = module.project01_public_subnet_bastion.subnet_id
  security_group_ids = [module.project01_bastion_sg.sg_id]
}

# WAS Server
# → 실제 애플리케이션 실행 서버
module "project01_was01_ec2" {
  source = "../../modules/ec2"
  subnet_id          = module.project01_private_subnet_was.subnet_id
  security_group_ids = [module.project01_was_sg.sg_id]
}

# DB Server
# → 데이터 저장 전용 서버
module "project01_db_ec2" {
  source = "../../modules/ec2"
  subnet_id          = module.project01_private_subnet_db.subnet_id
  security_group_ids = [module.project01_db_sg.sg_id]
}

############################################
# 6. LOAD BALANCER (ALB)
############################################

# ALB Security Group
# → 외부 HTTP/HTTPS 트래픽 허용
module "project01_alb_sg" {
  source = "../../modules/security-group"
  name   = "project01-alb-sg"
  vpc_id = module.project01_vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP 외부 트래픽"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS 외부 트래픽"
    }
  ]
}

# ALB
# → 사용자 트래픽을 WAS로 라우팅
# → health check + target group 포함
module "project01_alb" {
  source = "../../modules/alb"

  name               = "project01-alb"
  vpc_id             = module.project01_vpc.vpc_id

  subnet_ids = [
    module.project01_public_subnet_alb_a.subnet_id,
    module.project01_public_subnet_alb_b.subnet_id
  ]

  security_group_ids = [module.project01_alb_sg.sg_id]

  target_instance_ids = {
    was = module.project01_was01_ec2.instance_id
  }
}
