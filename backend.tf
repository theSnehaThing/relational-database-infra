terraform {
  backend "s3" {
    # Configuration provided via -backend-config flag
    # Use backend-configs/localstack.hcl for LocalStack
    # Use backend-configs/dev.hcl for Dev environment
    # Use backend-configs/test.hcl for Test environment  
    # Use backend-configs/prod.hcl for Prod environment
  }
}
