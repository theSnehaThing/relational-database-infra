#!/bin/bash

# run-local.sh - Complete local development setup and execution script
# This script follows all steps outlined in ReadmeLocal.md

set -e  # Exit on any error

LOG_FILE="runlocal.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Clear previous log
> "$LOG_FILE"

# Function to log messages
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Function to run command and log
run_cmd() {
    local cmd="$1"
    local description="$2"
    
    log "RUNNING: $description"
    log "COMMAND: $cmd"
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS: $description"
    else
        log "ERROR: $description failed"
        exit 1
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log "=========================================="
log "STARTING LOCAL DEVELOPMENT SETUP"
log "=========================================="

# Step 1: Check prerequisites
log "Step 1: Checking prerequisites..."

if command_exists docker; then
    log "✅ Docker is installed"
else
    log "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if command_exists terraform; then
    log "✅ Terraform is installed"
else
    log "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

if command_exists aws; then
    log "✅ AWS CLI is installed"
else
    log "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

if command_exists python3; then
    log "✅ Python 3 is installed"
else
    log "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Step 2: Setup Python virtual environment
log "Step 2: Setting up Python virtual environment..."

if [ ! -d "venv" ]; then
    run_cmd "python3 -m venv venv" "Create Python virtual environment"
fi

run_cmd "source venv/bin/activate" "Activate Python virtual environment"

# Install required packages
log "Installing required Python packages..."
run_cmd "pip install localstack awscli-local terraform-local" "Install Python packages"

# Step 3: Start LocalStack
log "Step 3: Starting LocalStack..."

# Check if LocalStack is already running
if curl -s http://localhost:4566/health >/dev/null 2>&1; then
    log "✅ LocalStack is already running"
else
    run_cmd "localstack start -d" "Start LocalStack in detached mode"
    
    # Wait for LocalStack to be ready
    log "Waiting for LocalStack to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:4566/health >/dev/null 2>&1; then
            log "✅ LocalStack is ready"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            log "❌ LocalStack failed to start within 60 seconds"
            exit 1
        fi
    done
fi

run_cmd "curl -s http://localhost:4566/health" "Verify LocalStack health"

# Step 4: Start MySQL Docker Container
log "Step 4: Starting MySQL Docker container..."

# Check if MySQL container is already running
if docker ps | grep -q localstack-mysql; then
    log "✅ MySQL container is already running"
else
    # Remove existing container if it exists but is stopped
    if docker ps -a | grep -q localstack-mysql; then
        run_cmd "docker rm localstack-mysql" "Remove existing MySQL container"
    fi
    
    run_cmd "docker run -d --name localstack-mysql -e MYSQL_ROOT_PASSWORD=rootpassword -e MYSQL_DATABASE=shared_dev_db -p 3306:3306 mysql:8.0" "Start MySQL container"
    
    # Wait for MySQL to be ready
    log "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        if docker exec localstack-mysql mysql -u root -p'rootpassword' -e "SELECT 1;" >/dev/null 2>&1; then
            log "✅ MySQL is ready"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            log "❌ MySQL failed to start within 60 seconds"
            exit 1
        fi
    done
fi

run_cmd "docker ps | grep localstack-mysql" "Verify MySQL container is running"
run_cmd "docker exec localstack-mysql mysql -u root -p'rootpassword' -e 'SELECT 1;'" "Test MySQL connection"

# Step 5: Configure AWS CLI for LocalStack
log "Step 5: Configuring AWS CLI for LocalStack..."

run_cmd "aws configure set aws_access_key_id test" "Set AWS access key ID"
run_cmd "aws configure set aws_secret_access_key test" "Set AWS secret access key"
run_cmd "aws configure set region eu-west-1" "Set AWS region"
run_cmd "aws configure set output json" "Set AWS output format"

run_cmd "awslocal s3 ls" "Test LocalStack connectivity"

# Step 6: Initialize Terraform
log "Step 6: Initializing Terraform..."

run_cmd "terraform init" "Initialize Terraform"
run_cmd "terraform validate" "Validate Terraform configuration"

# Step 7: Plan Infrastructure
log "Step 7: Planning infrastructure..."

run_cmd "terraform plan -var-file=envs/localstack.tfvars" "Plan infrastructure deployment"

# Step 8: Deploy Infrastructure
log "Step 8: Deploying infrastructure..."

run_cmd "terraform apply -var-file=envs/localstack.tfvars -auto-approve" "Deploy infrastructure"

# Display outputs
log "Infrastructure outputs:"
terraform output >> "$LOG_FILE" 2>&1

# Step 9: Verify Database Configuration
log "Step 9: Verifying database configuration..."

# Check created databases
run_cmd "docker exec localstack-mysql mysql -u root -p'rootpassword' -e 'SHOW DATABASES;'" "List all databases"

# Check created users
run_cmd "docker exec localstack-mysql mysql -u root -p'rootpassword' -e \"SELECT User, Host FROM mysql.user WHERE User LIKE 'local-%' OR User LIKE 'base_%';\"" "List database users"

# Step 10: Test Infrastructure
log "Step 10: Running infrastructure tests..."

# Make test script executable
chmod +x test-infrastructure.sh

# Run the test script
if ./test-infrastructure.sh; then
    log "✅ All infrastructure tests passed!"
else
    log "❌ Some infrastructure tests failed. Check the log for details."
    exit 1
fi

# Step 11: Display connection information
log "Step 11: Displaying connection information..."

log "=========================================="
log "SETUP COMPLETED SUCCESSFULLY!"
log "=========================================="

# Get outputs for display
DATABASE_NAME=$(terraform output -raw database_name 2>/dev/null || echo "N/A")
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "N/A")
RDS_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "N/A")
BASE_SCHEMA_NAME=$(terraform output -raw base_schema_name 2>/dev/null || echo "N/A")

log "Connection Information:"
log "  Main Database: $DATABASE_NAME"
log "  Base Schema: $BASE_SCHEMA_NAME"
log "  Endpoint: $RDS_ENDPOINT"
log "  Port: $RDS_PORT"
log ""
log "User Credentials:"
log "  Stored in AWS Secrets Manager (LocalStack)"
log "  Access via: awslocal secretsmanager get-secret-value --secret-id [secret-name]"
log ""
log "Available User Schemas:"
log "  - local-euwest1-piet_schema"
log "  - local-euwest1-klass_schema" 
log "  - local-euwest1-piet2_schema"
log "  - local-euwest1-henk_schema"
log "  - local-euwest1-jan_schema"
log "  - local-euwest1-kees_schema"
log "  - local-euwest1-kees2_schema"
log ""
log "User Roles (as configured):"
log "  - piet: developer"
log "  - klass: admin"
log "  - piet2: developer"
log "  - henk: manager"
log "  - jan: developer"
log "  - kees: developer"
log "  - kees2: developer"
log ""
log "Next Steps:"
log "  1. Connect to databases using the credentials from Secrets Manager"
log "  2. Test user permissions and schema access"
log "  3. Develop and test your applications"
log "  4. Monitor logs with: tail -f $LOG_FILE"
log ""
log "Cleanup (when done):"
log "  1. terraform destroy -var-file=envs/localstack.tfvars -auto-approve"
log "  2. docker stop localstack-mysql && docker rm localstack-mysql"
log "  3. localstack stop"
log ""
log "All operations logged to: $LOG_FILE"

exit 0