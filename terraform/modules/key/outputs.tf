# modules/key/outputs.tf

output "key_name" {
  description = "생성된 키 페어의 이름"
  value       = aws_key_pair.this.key_name
}