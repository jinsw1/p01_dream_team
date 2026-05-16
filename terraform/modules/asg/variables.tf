# modules/asg/variables.tf

# 변수 정의 
variable "region" { default = "ap-northeast-2" }
variable "instance_type" { default = "t3.micro" }

# 오토스케일링 그룹에서 원하는 ec2의 갯수
variable "desired_capacity" { default = 2 }

# 오토스케일링 그룹에서 원하는 최소 ec2의 갯수
variable "min_size" { default = 1 }

# 오토스케일링 그룹에서 원하는 최대 ec2의 갯수
variable "max_size" { default = 5 }

# 첫번째 가용영역
variable "avail_zone_1" { default = "ap-northeast-2a" }

# 두번째 가용영역
variable "avail_zone_2" { default = "ap-northeast-2c" }
