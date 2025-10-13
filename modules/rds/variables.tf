variable "environment" {
  type = string
}

variable "master_username" {
  type = string
  default = "admin"
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

variable "tag" {
  type = map(string)
}

variable "db_name" {
  type = string
}

variable "aws_region" {
  type = string
}