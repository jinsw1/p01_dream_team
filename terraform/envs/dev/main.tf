# 1. provider 설정
provider "aws" {
	region = "ap-northeast-2" # 서울 리전  
}

#vpc 및 네트워크 생성
module "vpc" {
  source = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "dev-vpc"
}