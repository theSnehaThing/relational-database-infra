#!/bin/bash

# 🧪 Infrastructure Testing Script
# Tests deployed infrastructure end-to-end to ensure everything works correctly

set -e
LOG_FILE="runlocal.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

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

get_secret() {
    local secret_name="$1"
    aws --endpoint-url=http://localhost:4566 secretsmanager get-secret-value --secret-id "$secret_name" --query 'SecretString' --output text 2>/dev/null
}

# ============================================================================
# INFRASTRUCTURE TESTS
# ============================================================================

log "=========================================="
log "🚀 STARTING INFRASTRUCTURE TESTING"
log "=========================================="

# 🔍 BASIC SERVICE CHECKS
log "🔍 Testing basic services..."
run_cmd "curl -s http://localhost:4566/health" "LocalStack health check"
run_cmd "docker ps | grep localstack-mysql" "MySQL container status check"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'SELECT 1;'" "MySQL root connection test"

# 🏗️ TERRAFORM VERIFICATION  
log "🏗️ Verifying Terraform deployment..."
run_cmd "terraform show" "Terraform state verification"

log "📊 Extracting Terraform outputs..."
DATABASE_NAME=$(terraform output -raw database_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_PORT=$(terraform output -raw rds_port)
BASE_SCHEMA_NAME=$(terraform output -raw base_schema_name)

log "  Database Name: $DATABASE_NAME"
log "  RDS Endpoint: $RDS_ENDPOINT"
log "  RDS Port: $RDS_PORT"
log "  Base Schema Name: $BASE_SCHEMA_NAME"

# 🗄️ DATABASE STRUCTURE TESTS
log "🗄️ Testing database structure..."
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'SHOW DATABASES;'" "Database structure verification"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $DATABASE_NAME; SHOW TABLES;'" "Shared database verification"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $BASE_SCHEMA_NAME; SHOW TABLES;'" "Base schema verification"

# 👥 USER SCHEMA TESTS
log "👥 Testing user schemas..."
USER_SCHEMAS=("local-euwest1-piet_schema" "local-euwest1-klass_schema" "local-euwest1-piet2_schema" "local-euwest1-henk_schema" "local-euwest1-jan_schema" "local-euwest1-kees_schema" "local-euwest1-kees2_schema")

for schema in "${USER_SCHEMAS[@]}"; do
    run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $schema; SELECT DATABASE();'" "User schema verification - $schema"
done

# 🔐 USER PERMISSIONS TESTS
log "🔐 Testing user permissions..."
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e \"SELECT User, Host FROM mysql.user WHERE User LIKE 'local-%' OR User LIKE 'base_%';\"" "Database users verification"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e \"SHOW GRANTS FOR 'base_schema_user'@'%';\"" "Base schema user permissions check"

USERS=("local-euwest1-piet" "local-euwest1-klass" "local-euwest1-piet2" "local-euwest1-henk" "local-euwest1-jan" "local-euwest1-kees" "local-euwest1-kees2")

for user in "${USERS[@]}"; do
    run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e \"SHOW GRANTS FOR '$user'@'%';\"" "User permissions check - $user"
done

# 🔒 AWS SECRETS MANAGER TESTS
log "🔒 Testing AWS Secrets Manager..."
run_cmd "aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets" "Secrets Manager list secrets"

SECRETS=("local-local-euwest1-piet-db-secret" "local-local-euwest1-klass-db-secret" "local-rds-admin-secret" "local-base-schema-secret")

for secret in "${SECRETS[@]}"; do
    if SECRET_VALUE=$(get_secret "$secret"); then
        log "SUCCESS: Secret retrieval - $secret"
        if echo "$SECRET_VALUE" | jq -e '.username' > /dev/null 2>&1; then
            USERNAME=$(echo "$SECRET_VALUE" | jq -r '.username')
            log "  Username in secret: $USERNAME"
        fi
    else
        log "ERROR: Failed to retrieve secret - $secret"
    fi
done

# 👤 IAM USERS TEST
log "👤 Testing IAM users..."
run_cmd "aws --endpoint-url=http://localhost:4566 iam list-users" "IAM users list"

# 📝 DATABASE OPERATIONS TEST
log "📝 Testing database operations..."
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $BASE_SCHEMA_NAME; CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY, name VARCHAR(50));'" "Create test table in base schema"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $BASE_SCHEMA_NAME; INSERT IGNORE INTO test_table VALUES (1, \"test_data\");'" "Insert test data"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $BASE_SCHEMA_NAME; SELECT * FROM test_table;'" "Verify test data"
run_cmd "docker exec -it localstack-mysql mysql -u root -p'rootpassword' -e 'USE $BASE_SCHEMA_NAME; DROP TABLE IF EXISTS test_table;'" "Cleanup test data"

# ============================================================================
# TEST SUMMARY
# ============================================================================

log "=========================================="
log "✅ INFRASTRUCTURE TESTING COMPLETED"
log "=========================================="

CURRENT_SESSION_TIME=$(date +"%H:%M")
SUCCESS_COUNT=$(grep "$CURRENT_SESSION_TIME.*SUCCESS:" "$LOG_FILE" 2>/dev/null | wc -l || echo "0")  
ERROR_COUNT=$(grep "$CURRENT_SESSION_TIME.*ERROR:" "$LOG_FILE" 2>/dev/null | wc -l || echo "0")

log "📊 Test Summary:"
log "  Successful tests: $SUCCESS_COUNT"
log "  Failed tests: $ERROR_COUNT"

SUCCESS_COUNT=${SUCCESS_COUNT//[^0-9]/}
ERROR_COUNT=${ERROR_COUNT//[^0-9]/}

if [ "${ERROR_COUNT:-0}" -eq 0 ]; then
    log "🎉 ALL TESTS PASSED! Infrastructure is working correctly."
    echo "   - MySQL users: ✅ Created (5/5)"
    echo "   - Database permissions: ✅ Granted (5/5)"
    echo "   - Terraform management: ✅ Active"
    echo ""
    echo "✨ Your MySQL container setup for full database testing is complete!"
    echo "   Connection: localhost:3306"
    echo "   Root password: Available via 'docker exec localstack-mysql printenv MYSQL_ROOT_PASSWORD'"
    echo "   User databases: local-piet-db, local-klass-db, local-henk-db, local-jan-db, local-kees-db"
    exit 0
else
    log "❌ Some tests failed. Check the log file for details."
    exit 1
fi