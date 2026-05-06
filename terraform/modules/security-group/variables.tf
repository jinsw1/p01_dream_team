# modules/security-group/variables.tf

variable "vpc_id" {
  description = "보안 그룹이 속할 VPC ID"
  type        = string
}

variable "sg_name" {
  description = "보안 그룹의 이름"
  type        = string
}

variable "ingress_ports" {
  description = "허용할 인바운드 포트 번호 리스트 ex) [22, 80])"
  type        = list(number)
}