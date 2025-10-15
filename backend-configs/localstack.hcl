bucket = "sol-terraform-state-bucket-local"
key    = "localstack/terraform.tfstate"
region = "eu-west-1"
dynamodb_table = "terraform-state-locks-local"
encrypt = true

# LocalStack specific settings
endpoint = "http://localhost:4566"
dynamodb_endpoint = "http://localhost:4566"
force_path_style = true
skip_credentials_validation = true
skip_metadata_api_check = true
skip_region_validation = true