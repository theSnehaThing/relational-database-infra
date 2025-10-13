terraform {
  backend "s3" {
    bucket = "terraform-state-sol"
    key    = "relational-database-infra/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-state-locks"
    encrypt = true
  }
}