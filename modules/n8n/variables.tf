variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_id" {
  type = string
}

variable "container_image" {
  type = string
}

variable "name" {
  type = string
}

variable "ingress_cidr" {
  type = string
}

variable "namespace_id" {
  type = string
}

variable "app_host" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "zone_id_private" {
  type = string
}

variable "alb_dns" {
  type = string
}

variable "container_port" {
  type = number
}

variable "listener_arn" {
  type = string
}

variable "rule_priority" {
  type = number
}

variable "DB_POSTGRESDB_HOST" {
  type = string
}

variable "DB_HOST_internal" {
  type = string
}

variable "DB_POSTGRESDB_DATABASE" {
  type = string
}

variable "DB_POSTGRESDB_USER" {
  type = string
}

variable "DB_POSTGRESDB_PASSWORD" {
  type = string
}

variable "DB_POSTGRESDB_PORT" {
  type = number
}

variable "DB_TYPE" {
  type = string
}

variable "DB_POSTGRESDB_SCHEMA" {
  type = string
}