# 1. RSA Private Key 생성 (로컬에서 생성됨)
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. AWS Key Pair 등록
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
}

# 3. Private Key 파일 로컬 저장 (중요)
resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  #filename       = "${path.module}/${var.key_name}.pem"
  filename        = pathexpand("~/.ssh/${var.key_name}.pem")
  file_permission = "0400"
}

# 4. AWS Secrets Manager에 Private Key 저장 
# 껍데기 secrets 상자 만들기
resource "aws_secretsmanager_secret" "private_key" {
  name                    = "ssh-keys/${var.key_name}"  #식별자 이름 (이 이름으로 파일 저장 아님)
  description             = "Private SSH key for ${var.key_name}"
  recovery_window_in_days = 0   # destroy 시 즉시 삭제 숫자를 30으로 설정하면 destory 해도 30일 뒤에 삭제
}
#secrets 상자에 pem 파일 직접 넣기
resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.this.private_key_pem
}