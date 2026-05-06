# modules/ec2/variables.tf

variable "name" {
  description = "EC2 이름"
}

variable "subnet_id" {
  description = "배치할 서브넷 ID"
}

variable "sg_ids" {
  description = "적용할 보안그룹 ID 리스트"
  type        = list(string)
}

variable "key_name" {
  description = "접속할 Key Pair 이름"
}

variable "instance_type" {
  description = "인스턴스 타입"
  default     = "t3.micro"
}