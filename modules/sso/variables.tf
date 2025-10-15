variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "username" {
  description = "Username (derived from email)"
  type        = string
}

variable "first_name" {
  description = "User first name"
  type        = string
}

variable "last_name" {
  description = "User last name"
  type        = string
}

variable "email" {
  description = "User email address"
  type        = string
}

variable "role" {
  description = "User role (developer, admin, manager)"
  type        = string
  default     = "developer"
}

variable "secret_arn" {
  description = "ARN of the user's secret in Secrets Manager"
  type        = string
}

variable "tag" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}