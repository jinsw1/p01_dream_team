# modules/subnet/variables.tf

variable "vpc_id" {
  description = "서브넷이 속할 VPC ID"
  type = string
}

variable "cidr_block" {
  description = "서브넷의 IP 대역"
  type        = string
}

variable "az" {
  description = "가용영역 (ap-northeast-2a)"
  type        = string
}

variable "map_public_ip" {
  description = "퍼블릭 서브넷 여부 (true면 공인 IP 자동 할당)"
  type        = bool
  default     = false # 기본은 프라이빗으로 설정
}

variable "subnet_name" {
  description = "서브넷 이름"
  type        = string
}

variable "igw_id" {
  description = "인터넷 게이트웨이 ID (퍼블릭 서브넷일 때만 필요함)"
  type        = string
  default     = null 
}