terraform {
  backend "s3" {
    bucket         = "project01-tfstate-bucket-mk"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "dream-team-terraform-lock-mk" #dream-team-terraform-lock	terraform-lock
	encrypt = true # tstate 에는 민감한 정보가 들어있어 암호화
  }
}