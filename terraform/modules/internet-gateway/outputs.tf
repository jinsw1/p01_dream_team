# modules/internet-gateway/outputs.tf

output "igw_id" {
  description = "생성된 igw의 id"
  value = aws_internet_gateway.this.id
}

