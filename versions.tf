terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}
