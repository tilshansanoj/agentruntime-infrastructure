variable "base_domain_name" {
  description = "The base domain (i.e. useferry.com)."
  type        = string
}

variable "r53_primary_zone_public_ds_record" {
  description = "DS record for the VPC primary domain PUBLIC."
  type        = string
}

variable "vpc_primary_domain" {
  description = "Primary DNS domain name."
  type        = string
}

variable "vpc_primary_domain_nameservers" {
  description = "List of NSes for the PUBLIC zone for this domain."
  type        = list(string)
}

variable "vpc_name_short" {
  description = "Short VPC name, lowercased."
  type        = string
}

variable "account_id" {
  description = "AWS account ID where the top-level domain is hosted."
  type        = string
}