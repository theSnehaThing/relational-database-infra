variable "environment" {
  type = string
}

variable "master_username" {
  description = "Master username for RDS instance"
  type = string
  default = "db_admin"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_instance_class" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "publicly_accessible" {
  type = bool
}

variable "aws_region" {
  type = string
}

variable "tag" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}