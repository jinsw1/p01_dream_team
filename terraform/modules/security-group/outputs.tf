# modules/security-group/outputs.tf

output "sg_id" {
  description = "생성된 보안 그룹의 ID"
  value       = aws_security_group.this.id
}