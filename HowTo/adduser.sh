#!/bin/bash

# Add users from CSV to specific environment

set -e

LOG_FILE="user-management.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_usage() {
    cat << EOF
Usage: $0 <users.csv> <environment>

Add users from CSV file to specific environment.

Arguments:
  users.csv     CSV file with user data
  environment   Environment name (local, localstack, dev, prod, etc.)

CSV Format:
FirstName,LastName,Email,Role
Klaas,Klassen,klass@2solar.nl,admin

Valid roles: developer, admin, manager
Note: 'local' environment will use localstack.tfvars file
EOF
}

validate_csv() {
    local csv_file="$1"
    
    if [[ ! -f "$csv_file" ]]; then
        echo "Error: CSV file '$csv_file' not found"
        return 1
    fi
    
    local line_count=$(wc -l < "$csv_file")
    if [[ $line_count -eq 1 ]]; then
        echo "Error: CSV file is empty (only headers found)"
        return 1
    fi
    
    local header=$(head -n1 "$csv_file")
    if [[ "$header" != "FirstName,LastName,Email,Role" ]]; then
        echo "Error: Invalid CSV header. Expected: FirstName,LastName,Email,Role"
        return 1
    fi
    
    return 0
}

get_tfvars_file() {
    local env="$1"
    
    # Handle local -> localstack mapping
    if [[ "$env" == "local" ]]; then
        if [[ -f "envs/localstack.tfvars" ]]; then
            echo "envs/localstack.tfvars"
            return 0
        elif [[ -f "envs/local.tfvars" ]]; then
            echo "envs/local.tfvars"
            return 0
        fi
    else
        if [[ -f "envs/${env}.tfvars" ]]; then
            echo "envs/${env}.tfvars"
            return 0
        fi
    fi
    
    return 1
}

validate_environment() {
    local env="$1"
    
    if tfvars_file=$(get_tfvars_file "$env"); then
        echo "Using tfvars file: $tfvars_file"
        return 0
    else
        echo "Error: No environment file found for '$env'"
        echo "Looked for:"
        if [[ "$env" == "local" ]]; then
            echo "  - envs/localstack.tfvars"
            echo "  - envs/local.tfvars"
        else
            echo "  - envs/${env}.tfvars"
        fi
        return 1
    fi
}

validate_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_role() {
    local role="$1"
    case "$role" in
        developer|admin|manager) return 0 ;;
        *) return 1 ;;
    esac
}

process_csv() {
    local csv_file="$1"
    local users_tf=""
    local line_num=1
    local user_count=0
    
    while IFS=',' read -r first_name last_name email role; do
        line_num=$((line_num + 1))
        
        # Skip header
        if [[ "$first_name" == "FirstName" ]]; then
            continue
        fi
        
        # Trim whitespace
        first_name=$(echo "$first_name" | xargs)
        last_name=$(echo "$last_name" | xargs)
        email=$(echo "$email" | xargs)
        role=$(echo "$role" | xargs)
        
        # Validate required fields
        if [[ -z "$first_name" || -z "$last_name" || -z "$email" || -z "$role" ]]; then
            echo "Error line $line_num: All fields are mandatory (FirstName,LastName,Email,Role)"
            return 1
        fi
        
        if [[ ! "$first_name" =~ ^[A-Za-z]+$ ]]; then
            echo "Error line $line_num: Invalid first name '$first_name'"
            return 1
        fi
        
        if [[ ! "$last_name" =~ ^[A-Za-z]+$ ]]; then
            echo "Error line $line_num: Invalid last name '$last_name'"
            return 1
        fi
        
        if ! validate_email "$email"; then
            echo "Error line $line_num: Invalid email '$email'"
            return 1
        fi
        
        if ! validate_role "$role"; then
            echo "Error line $line_num: Invalid role '$role'. Valid: developer, admin, manager"
            return 1
        fi
        
        users_tf+="  {
    first_name = \"$first_name\"
    last_name  = \"$last_name\"
    email      = \"$email\"
    role       = \"$role\"
  },"$'\n'
        
        user_count=$((user_count + 1))
        echo "Validated: $first_name $last_name ($email) - $role" >&2
        
    done < "$csv_file"
    
    echo "$users_tf"
    return 0
}

add_users_to_tfvars() {
    local tfvars_file="$1"
    local new_users="$2"
    
    # Backup original
    cp "$tfvars_file" "${tfvars_file}.backup.$(date +%s)"
    
    # Create temporary file with new users
    echo "$new_users" > /tmp/new_users.tmp
    
    # Add users before closing ]
    awk '
    /^\]$/ && in_user_block {
        while ((getline line < "/tmp/new_users.tmp") > 0) {
            print line
        }
        close("/tmp/new_users.tmp")
        print $0
        in_user_block = 0
        next
    }
    /^user = \[/ { 
        in_user_block = 1
    }
    { print $0 }
    ' "$tfvars_file" > "${tfvars_file}.tmp"
    
    mv "${tfvars_file}.tmp" "$tfvars_file"
    rm -f /tmp/new_users.tmp
}

reset_csv() {
    local csv_file="$1"
    cat > "$csv_file" << EOF
FirstName,LastName,Email,Role
EOF
}

# Check arguments
if [[ $# -ne 2 ]]; then
    print_usage
    exit 1
fi

CSV_FILE="$1"
ENVIRONMENT="$2"

log "Starting user addition for environment: $ENVIRONMENT"

# Validate inputs
if ! validate_csv "$CSV_FILE"; then
    exit 1
fi

if ! validate_environment "$ENVIRONMENT"; then
    exit 1
fi

# Get the actual tfvars file to use
TFVARS_FILE=$(get_tfvars_file "$ENVIRONMENT")

if ! command -v terraform &> /dev/null; then
    echo "Error: terraform not found"
    exit 1
fi

# Process CSV
log "Processing CSV file: $CSV_FILE"
if NEW_USERS=$(process_csv "$CSV_FILE"); then
    echo "All users validated successfully"
else
    exit 1
fi

# Add users to tfvars
log "Adding users to $TFVARS_FILE"
add_users_to_tfvars "$TFVARS_FILE" "$NEW_USERS"

# Run Terraform workflow
log "Running terraform init..."
if ! terraform init; then
    log "Terraform init failed"
    exit 1
fi

log "Running terraform validate..."
if ! terraform validate; then
    log "Terraform validate failed"
    exit 1
fi

log "Running terraform plan..."
if ! terraform plan -var-file="$TFVARS_FILE"; then
    log "Terraform plan failed"
    exit 1
fi

log "Running terraform apply..."
if terraform apply -var-file="$TFVARS_FILE" -auto-approve; then
    log "Terraform apply successful"
else
    log "Terraform apply failed"
    exit 1
fi

# Show results
echo ""
echo "SUCCESS: Users added to environment '$ENVIRONMENT'"
echo ""

first_names=($(echo "$NEW_USERS" | grep "first_name" | sed 's/.*"\(.*\)"/\1/'))
emails=($(echo "$NEW_USERS" | grep "email" | sed 's/.*"\(.*\)"/\1/'))

for i in "${!first_names[@]}"; do
    first_name="${first_names[$i]}"
    email="${emails[$i]}"
    username=$(echo "$first_name" | tr '[:upper:]' '[:lower:]')
    
    echo "User: $first_name ($email)"
    echo "  IAM User: ${ENVIRONMENT}-euwest1-${username}"
    echo "  Schema: ${ENVIRONMENT}-euwest1-${username}_schema"
    echo "  Secret: ${ENVIRONMENT}-${ENVIRONMENT}-euwest1-${username}-db-secret"
    echo ""
done

# Reset CSV
reset_csv "$CSV_FILE"
log "Reset $CSV_FILE for next use"
log "User addition completed successfully"