# modules/vpc/variables.tf

variable "cidr_block" {
  description = "VPC에 사용할 IP 대역"
  type        = string
}

variable "vpc_name" {
  description = "VPC 이름"
  type        = string
}