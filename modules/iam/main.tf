locals {
  iam_name = "${var.username}-${var.environment}-iam-${var.suffix}"
}

resource "aws_iam_user" "user" {
  name = local.iam_name
  path = "/users/${var.username}-${var.environment}/"
  tags = {
        Environment = var.environment
        ManagedBy   = "Terraform"
    }
}

data "aws_iam_policy_document" "own_secret" {
  statement {
    sid = "AllowReadOwnSecret"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.secret_arn]
    effect = "Allow"
  }
}

resource "aws_iam_user_policy" "read_own_secret" {
  name   = "${local.iam_name}-secret-policy"
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.own_secret.json
  
}

output "user_name" {
    value = aws_iam_user.name.name
}