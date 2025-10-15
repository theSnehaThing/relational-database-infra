# Check if running in LocalStack environment
locals {
  is_localstack = contains(["local", "localstack", "sso-local", "sso-test"], var.environment)
}

# Real AWS SSO Resources (only created when not in LocalStack)
# Get SSO instances
data "aws_ssoadmin_instances" "current" {
  count = local.is_localstack ? 0 : 1
}

# Permission Set for Database Access based on role
resource "aws_ssoadmin_permission_set" "database_access" {
  count = local.is_localstack ? 0 : 1
  
  name             = "${var.environment}-database-${var.role}-${var.username}"
  description      = "Database access permission set for ${var.role} - ${var.first_name} ${var.last_name}"
  instance_arn     = tolist(data.aws_ssoadmin_instances.current[0].arns)[0]
  session_duration = "PT8H"  # 8 hours session

  tags = var.tag
}

# Inline policy for Secrets Manager access (user can only access their own secret)
resource "aws_ssoadmin_permission_set_inline_policy" "database_policy" {
  count = local.is_localstack ? 0 : 1
  
  instance_arn       = tolist(data.aws_ssoadmin_instances.current[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.database_access[0].arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arn
        Sid = "AllowReadOwnSecret"
      },
      {
        Effect = "Allow" 
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
        Sid = "AllowRDSDescribe"
      }
    ]
  })
}

# Create SSO User in Identity Store
resource "aws_identitystore_user" "database_user" {
  count = local.is_localstack ? 0 : 1
  
  identity_store_id = tolist(data.aws_ssoadmin_instances.current[0].identity_store_ids)[0]
  
  display_name = "${var.first_name} ${var.last_name}"
  user_name    = var.username
  
  name {
    given_name  = var.first_name
    family_name = var.last_name
  }
  
  emails {
    value   = var.email
    primary = true
    type    = "work"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {
  count = local.is_localstack ? 0 : 1
}

# Assign permission set to user for the current account
resource "aws_ssoadmin_account_assignment" "database_assignment" {
  count = local.is_localstack ? 0 : 1
  
  instance_arn       = tolist(data.aws_ssoadmin_instances.current[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.database_access[0].arn

  principal_id   = aws_identitystore_user.database_user[0].user_id
  principal_type = "USER"

  target_id   = data.aws_caller_identity.current[0].account_id
  target_type = "AWS_ACCOUNT"
}

# LocalStack Simulation Resources (only created when in LocalStack)
# Create IAM user with SSO-like naming for LocalStack
resource "aws_iam_user" "sso_simulation_user" {
  count = local.is_localstack ? 1 : 0
  
  name = "${var.username}-sso-simulated"
  path = "/sso-users/${var.username}/"
  
  tags = merge(var.tag, {
    Name = "${var.username}-sso-simulated"
    SSOSimulation = "true"
    Environment = var.environment
    Role = var.role
  })
}

# Policy for accessing own secret only (LocalStack)
data "aws_iam_policy_document" "own_secret" {
  count = local.is_localstack ? 1 : 0
  
  statement {
    sid    = "AllowReadOwnSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [var.secret_arn]
  }
  
  statement {
    sid    = "AllowRDSDescribe"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters"
    ]
    resources = ["*"]
  }
}

# Attach policy to user (LocalStack)
resource "aws_iam_user_policy" "sso_simulation_policy" {
  count = local.is_localstack ? 1 : 0
  
  name   = "${var.username}-sso-simulated-policy"
  user   = aws_iam_user.sso_simulation_user[0].name
  policy = data.aws_iam_policy_document.own_secret[0].json
}