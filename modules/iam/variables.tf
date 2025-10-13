variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "username" {
  type = string
}


variable "secret_arn" {
  type = string
}

variable "tag" {
  type = map(string)
}

variable "suffix" {
  type = string
}