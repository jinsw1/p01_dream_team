data "aws_availability_zones" "available" {
  state = "available"
}

#vpc 및 네트워크 생성
module "vpc" {
  source          = "../../../modules/vpc"
  cidr_block      = "10.0.0.0/16"
  vpc_name        = "project01-vpc"
}

#igw 인터넷 게이트웨이 생성
module "igw" {
  source          = "../../../modules/internet-gateway"
  vpc_id          = module.vpc.vpc_id
  igw_name        = "project01-igw"
}

# public 서브넷 생성
module "public_subnet_bastion" {
  source          = "../../../modules/subnet"

  vpc_id          = module.vpc.vpc_id
  cidr_block      = "10.0.1.0/24"
  az              = data.aws_availability_zones.available.names[0]

  map_public_ip   = true
  igw_id          = module.igw.igw_id
  subnet_name     = "project01-public-subnet-bastion"
}

# private was 서브넷 생성
module "private_subnet_was" {
  source = "../../../modules/subnet"

  vpc_id           = module.vpc.vpc_id
  cidr_block       = "10.0.10.0/24"
  az               = data.aws_availability_zones.available.names[0]

  map_public_ip    = false
  subnet_name             = "project01-private-subnet-was"
}

# private db 서브넷 생성
module "private_subnet_db" {
  source = "../../../modules/subnet"

  vpc_id           = module.vpc.vpc_id
  cidr_block       = "10.0.20.0/24"
  az               = data.aws_availability_zones.available.names[0]

  map_public_ip    = false
  subnet_name             = "project01-private-subnet-db"
}

# 키 페어 설정
module "key_pair" {
  source   = "../../../modules/key"
  
  key_name = "project01-key" # 생성될 pem 파일의 이름
}

# mgmt용 보안 그룹 설정
module "sg_mgmt" {
  source        = "../../../modules/security-group"
  
  vpc_id        = module.vpc.vpc_id
  sg_name       = "project01-mgmt-sg"
  ingress_ports = [22]
}

# EC2_MGMT 생성
module "ec2_mgmt" {
  source        = "../../../modules/ec2"
  
  name          = "project01-mgmt-ec2"
  instance_type = "t3.micro"
  
  # 퍼블릭 서브넷에 배치
  subnet_id     = module.public_subnet_bastion.subnet_id 
  
  # 보안 그룹과 키 페어를 연결
  sg_ids        = [module.sg_mgmt.sg_id] 
  key_name      = module.key_pair.key_name
}

# # private db 서브넷 생성
# module "private_subnet_alb" {
# 	source = "./modules/subnet"	
# }