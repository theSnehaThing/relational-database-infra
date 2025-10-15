# Relational Database Infrastructure

Automated Terraform solution for managing shared development databases with individual developer access control.

## Overview

This project creates a scalable database infrastructure where multiple developers can access a shared MySQL database using their own credentials, with proper access controls and automated user management.

## Architecture

- **MySQL Database**: Shared RDS instance for development
- **Individual Access**: Each developer gets their own schema + access to shared base schema
- **IAM Integration**: Individual IAM users with restricted permissions
- **Secrets Management**: Database credentials stored securely in AWS Secrets Manager
- **Automated Provisioning**: Terraform handles both AWS resources and database users/permissions

## Prerequisites

- Terraform installed
- AWS CLI configured (for AWS environments)
- Docker running (for local development)

## Quick Start Guide

### 1. Local Development Setup

**Start Services:**
```bash
# Start LocalStack
localstack start -d

# Start MySQL Docker Container
docker run -d --name localstack-mysql -e MYSQL_ROOT_PASSWORD=rootpassword -p 3306:3306 mysql:8.0
```

**Configure AWS CLI:**
```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region eu-west-1
```

**Deploy Infrastructure:**
```bash
terraform init
terraform apply -var-file=envs/localstack.tfvars -auto-approve
```

### 2. Production Deployment

**Configure Environment:**
```bash
# Copy and edit production variables
cp envs/localstack.tfvars envs/prod.tfvars
# Edit envs/prod.tfvars with production settings
```

**Deploy:**
```bash
terraform apply -var-file=envs/prod.tfvars
```

## User Management Script

Simple script to add users to database infrastructure environments.

### Usage

```bash
./add-users.sh <users.csv> <environment>
```

### Steps

1. **Fill users.csv** with your user data:
```csv
FirstName,LastName,Email,Role
Piet,Pietersen,piet@2solar.nl,developer
Klaas,Klassen,klass@2solar.nl,admin
```

2. **Run the script** with environment:
```bash
./add-users.sh users.csv local
```

3. **Script will**:
   - Validate CSV format and data
   - Check environment exists
   - Add users to environment tfvars
   - Run terraform workflow
   - Show created resources
   - Reset CSV for next use

### Requirements

- All CSV fields are mandatory
- Valid roles: `developer`, `admin`, `manager`
- Environment file must exist: `envs/{env}.tfvars`
- Terraform must be installed

### Examples

```bash
# Local environment
./add-users.sh users.csv local

# Development environment  
./add-users.sh users.csv dev

# Production environment
./add-users.sh users.csv prod
```

### Output

After successful execution, you'll see:
- IAM usernames
- Database schema names  
- Secret names for credentials
- Access permissions granted

The CSV file gets reset to headers only after successful completion.

## What Gets Created

For each user, the system creates:
- **IAM User**: `{env}-euwest1-{firstname}`
- **Database Schema**: `{env}-euwest1-{firstname}_schema`
- **Secret**: `{env}-{env}-euwest1-{firstname}-db-secret`
- **Database User**: With appropriate permissions

## Access Levels

- **developer**: Own schema + shared base schema (read/write)
- **admin**: Enhanced database privileges
- **manager**: Management access levels

## Getting Credentials

Retrieve database credentials for a user:
```bash
# AWS
aws secretsmanager get-secret-value --secret-id {secret-name}

# LocalStack
awslocal secretsmanager get-secret-value --secret-id {secret-name}
```

## Testing

Verify your deployment:
```bash
./test-infrastructure.sh
```

## Cleanup

```bash
# Destroy infrastructure
terraform destroy -var-file=envs/{env}.tfvars -auto-approve

# Stop local services (if using LocalStack)
docker stop localstack-mysql && docker rm localstack-mysql
localstack stop
```

## Project Structure

```
├── main.tf                    # Root module
├── variables.tf               # Variable definitions
├── envs/
│   ├── localstack.tfvars     # Local development config
│   └── prod.tfvars           # Production config
├── modules/
│   ├── rds/                  # Database infrastructure
│   ├── iam/                  # User management
│   ├── secrets/              # Credential storage
│   └── db_user_access/       # Database permissions
├── add-users.sh              # User management script
├── users.csv                 # User input file
└── test-infrastructure.sh    # Verification script
```

## Resources

- [LocalStack RDS Documentation](https://docs.localstack.cloud/aws/services/rds/)
- [Terraform AWS RDS Module](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest)
- [MySQL Terraform Provider](https://registry.terraform.io/providers/petoju/mysql/latest/docs)
- [AWS RDS Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [Aurora vs RDS Comparison](https://www.cloudzero.com/blog/aurora-vs-rds/)

