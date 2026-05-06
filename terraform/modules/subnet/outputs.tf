# modules/subnet/outputs.tf

output "subnet_id" {
  description = "생성된 서브넷의 ID"
  value       = aws_subnet.this.id 
}