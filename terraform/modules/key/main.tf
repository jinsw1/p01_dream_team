# modules/key/main.tf


# 알고리즘 결정
resource "tls_private_key" "this" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# 키등록
resource "aws_key_pair" "this" {
    key_name   = "var.key_name"
    public_key = tls_private_key.this.public_key_openssh
}


# 개인키 가져오기
# "local_file" resource 를 이용하면 파일을 생성할수 있다.
resource "local_file" "this" {
    # ${path.module} 은 현재 실행경로(modules/key), {path.root) main.tf가 작동하는 곳(dev/base)를 의미한다.
    filename        = "${path.root}/${var.key_name}.pem"
    content         = tls_private_key.this.private_key_pem
    file_permission = "0600" # 파일의 권한 설정
}