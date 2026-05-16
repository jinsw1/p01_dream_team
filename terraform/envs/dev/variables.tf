# =========================================================================
# github secrets에 등록되어있는 ansible-key / bastion-key를 받아주는 변수 등록
# =========================================================================

variable "bastion-key" {
  description = "Bastion Private Key from GitHub Secrets"
  type        = string
  sensitive   = true    # 로그에 키 값이 노출되지 않게 보호
}

variable "ansible-key" {
  description = "Ansible Private Key from GitHub Secrets"
  type        = string
  sensitive   = true    # 로그에 키 값이 노출되지 않게 보호
}