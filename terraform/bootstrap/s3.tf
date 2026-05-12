resource "random_id" "bucket_suffix" {
    # 8 byte 크기의 렌덤한 문자열을 얻어내기 위한 설정
    byte_length = 8
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "project01-tfstate-bucket-${random_id.bucket_suffix.hex}"

  # 실수 방지 (삭제 방지)
  force_destroy = false
  tags = {
    Name = "project01-tfstate"
  }
}

# 버전 관리
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_enc" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
