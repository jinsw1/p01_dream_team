# modules/internet-gateway/variables.tf

variable "vpc_id" {
    description = "VPC 모듈에서 넘겨받을 ID"
    type = string
}
variable "igw_name" {
    description = "IGW 이름"
    type = string
}

