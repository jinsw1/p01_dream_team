variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "name" {
  type = string
}

variable "root_volume_size" {
  type    = number
  default = 8
}