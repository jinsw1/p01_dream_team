# modules/ec2/outputs.tf

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "EC2의 퍼블릭 IP"
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "EC2의 프라이빗 IP"
}