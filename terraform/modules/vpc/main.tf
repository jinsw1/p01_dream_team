resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}








# 1. provider 설정
provider "aws" {
	region = "ap-northeast-2" # 서울 리전  
}

# vpc
resource "aws_vpc" "proejct01_vpc" {
	cidr_block 				= "10.0.0.0/16"
	enable_dns_hostnames 	= true
	tags 					= { Name = "project01-vpc" }
}

# igw (인터넷 게이트웨이)
resource "aws_internet_gateway" "igw" {
  # 위에서 만들어진 vpc 의 아이디를 참조 하도록 한다.connection {
  vpc_id 	= aws_vpc.proejct01_vpc.id 
  tags  = {
	Name = "project01-igw" 
  }
}

#현재 리전에서 사용가능한(avaliable) 가용영역 데이터 가져오기
data "aws_availability_zones" "available"{
	state = "available"
}

# public subnet
resource "aws_subnet" "public_subnet_bastion" {
  vpc_id 					= aws_vpc.proejct01_vpc.id
  cidr_block 				= "10.0.1.0/24" # 256개의 ip 할당

  # data.aws_availability_zones.available.names 은 배열인데 거기에 여러개의 가용영역 데이터가 들어있다.
  # 그중 0번 방에 있는 데이터를 연결한다.
  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch 	= true # 이 방에 생기는 서버는 무조건 공인 ip를 받는다. false면 private_subnet
  tags = {
	Name = "lecture-subnet" 
  }
}

# private subnet was
resource "aws_subnet" "private_subnet_was" {
  vpc_id 					= aws_vpc.proejct01_vpc.id
  cidr_block 				= "10.0.10.0/24" # 256개의 ip 할당

  # data.aws_availability_zones.available.names 은 배열인데 거기에 여러개의 가용영역 데이터가 들어있다.
  # 그중 0번 방에 있는 데이터를 연결한다.
  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch 	= false # 이 방에 생기는 서버는 무조건 공인 ip를 받는다. false면 private_subnet
  tags = {
	Name = "project01-private-subnet-was"
  }
}


