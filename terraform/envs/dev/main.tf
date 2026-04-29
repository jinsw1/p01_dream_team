data "aws_availability_zones" "available" {
  state = "available"
}

#vpc 및 네트워크 생성
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "project01-vpc"
}

#igw 인터넷 게이트웨이 생성
module "igw" {
  source  = "./modules/internet_gateway"
  vpc_id  = module.vpc.vpc_id
  name    = "project01-igw"
}

# public 서브넷 생성
module "public_subnet_bastion" {
  source = "./modules/subnet"

  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.1.0/24"
  az                = data.aws_availability_zones.available.names[0]

  map_public_ip     = true
  name              = "project01-public-subnet-bastion"
}

# private was 서브넷 생성
module "private_subnet_was" {
  source = "./modules/subnet"

  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.10.0/24"
  az                = data.aws_availability_zones.available.names[0]

  map_public_ip     = false
  name              = "project01-private-subnet-was"
}

# private db 서브넷 생성
module "private_subnet_db" {
	source = "./modules/subnet"
}

# private db 서브넷 생성
module "private_subnet_alb" {
	source = "./modules/subnet"	
}