variable "public_subnet_id" {
  type        = list(string)
  description = "Public Subnet ids"
}

variable "alb_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "certificate_arn" {
   type = string
}

