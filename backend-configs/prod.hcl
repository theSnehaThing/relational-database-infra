bucket = "sol-terraform-state-bucket-prod"
key    = "prod/terraform.tfstate"
region = "eu-west-1"
dynamodb_table = "terraform-state-locks-prod"
encrypt = true