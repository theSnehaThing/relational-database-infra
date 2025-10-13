terraform {
  backend "s3" {
    bucket = "terraform-state-sol"
    key    = "relational-database-infra/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt = true
  }
}