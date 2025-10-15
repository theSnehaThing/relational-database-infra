# 🏗️ Local Development Setup Guide

A step-by-step guide to run the relational database infrastructure locally using LocalStack and Docker.

## 📋 Prerequisites

Ensure you have the following installed:
- **Docker** (running)
- **Terraform** 
- **AWS CLI**
- **Python 3.x** with virtual environment support

## 🏛️ Architecture

Since LocalStack Community edition doesn't support RDS, we use:
- **LocalStack** → AWS services (S3, IAM, Secrets Manager, DynamoDB)
- **MySQL Docker Container** → Database server
- **Terraform** → Infrastructure as code

## 🚀 Quick Start

### Step 1: Environment Setup
```bash
# Create and activate Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install localstack awscli-local terraform-local
```

### Step 2: Start Services
```bash
# Start LocalStack
localstack start -d

# Start MySQL Docker Container
docker run -d \
  --name localstack-mysql \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=shared_dev_db \
  -p 3306:3306 \
  mysql:8.0
```

### Step 3: Configure AWS CLI
```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region eu-west-1
aws configure set output json
```

### Step 4: Deploy Infrastructure
```bash
# Initialize and deploy
terraform init
terraform plan -var-file=envs/localstack.tfvars
terraform apply -var-file=envs/localstack.tfvars -auto-approve
```

## 🗄️ Database Configuration

### What Gets Created
- **Main Database**: `sol-local-active-euwest1-shared-database`
- **Base Schema**: `base_schema` (for team collaboration)  
- **User Schemas**: `local-euwest1-{username}_schema` (individual users)

### Available User Roles
- **developer**: Standard access (default)
- **admin**: Enhanced privileges  
- **manager**: Management access

### Verify Setup
```bash
# Check databases
docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e "SHOW DATABASES;"

# Check users  
docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e "SELECT User, Host FROM mysql.user WHERE User LIKE 'local-%';"
```

## 👥 User Management

Configure users in `envs/localstack.tfvars`:

```hcl
user = [
  {
    first_name = "Piet"
    last_name  = "Pietersen" 
    email      = "piet@2solar.nl"
    role       = "developer"  # Optional: developer|admin|manager
  },
  {
    first_name = "Klaas"
    last_name  = "Klassen"
    email      = "klass@2solar.nl"  
    role       = "admin"
  }
]
```

## 🔐 Access Credentials

Get user database credentials from Secrets Manager:

```bash
# List all secrets
awslocal secretsmanager list-secrets

# Get specific user credentials  
awslocal secretsmanager get-secret-value --secret-id local-local-euwest1-piet-db-secret
```

## ✅ Testing

Verify everything works:

```bash
chmod +x test-infrastructure.sh
./test-infrastructure.sh
```

## 🧹 Cleanup

When done developing:

```bash
# Destroy infrastructure
terraform destroy -var-file=envs/localstack.tfvars -auto-approve

# Stop containers  
docker stop localstack-mysql
docker rm localstack-mysql
localstack stop

# Exit virtual environment
deactivate
```

## 🔧 Troubleshooting

**LocalStack Issues**
```bash
localstack logs
curl http://localhost:4566/health
```

**MySQL Issues**  
```bash
docker logs localstack-mysql
docker exec -it localstack-mysql mysql -u root -p'rootpassword'
```

**Terraform Issues**
```bash
terraform validate
terraform fmt
```

**VS Code Issues**
- Disable `betajob.modulestf` extension if installed

**View Logs**
```bash
tail -f runlocal.log
```

## 📁 Project Structure

```
├── main.tf                    # Root module
├── variables.tf               # Variable definitions  
├── envs/localstack.tfvars    # Local environment config
├── modules/
│   ├── rds/                  # Database module
│   ├── iam/                  # User management
│   ├── secrets/              # Credential storage
│   └── db_user_access/       # Database access control
├── test-infrastructure.sh    # Verification script
└── runlocal.log             # Execution logs
```

## ✨ Next Steps

After deployment:
1. Connect to databases using provided credentials
2. Test user permissions and schema access  
3. Develop and test your applications
4. Scale configuration for production