variable "environment" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "db_endpoint" {
  type = string
}
variable "db_port" {
  type = string
}
variable "rds_master_secret_arn" {
  type = string
}
variable "users" {
  type = map(any)
}
variable "create_users" {
  type = bool
  default = false
}
variable "tag" {
  type = map(string)
}
