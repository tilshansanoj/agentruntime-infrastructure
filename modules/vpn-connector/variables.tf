variable "name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "vpc_primary_domain" {
  type = string
}

variable "secret_manager_arn" {
  type = string
}

# variable "management_ingress_rules" {
#   description = "Rules that allow non-VPN access to resources with EIPs."
#   type = map(object({
#     type              = string
#     from_port         = number
#     to_port           = number
#     protocol          = string
#     cidr_blocks       = list(string)
#     security_group_id = list(string)
#     description       = string
#   }))
# }

variable "vpc_id" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
}

variable "ssh_key" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "zone_id_private" {
  type = string
}

variable "zone_id_public" {
  type = string
}

