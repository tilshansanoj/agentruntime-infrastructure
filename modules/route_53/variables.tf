variable "enviroment" {
  description = "What we set the Name:tag to."
  type        = string
}

variable "vpc_primary_domain" {
  description = "Primary DNS domain name."
  type        = string
}

variable "base_domain_name" {
  description = "The base domain (i.e. useferry.com)."
  type        = string
}

variable "vpc_name_short" {
  description = "What we set the Name:tag to."
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "account_id" {
  description = "account id"
  type        = string
}