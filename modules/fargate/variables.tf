variable "name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "public_subnet_id" {
  type        = list(string)
  description = "Public Subnet ids"
}

variable "ingress_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "rule_priority" {
  type = number
}

variable "task_count" {
  type = number
}

variable "image" {
  type = string
}


variable "health_check_path" {
  type = string
}

variable "alb_dns" {
  type = string
}

variable "alb-arn" {
  type = string
}

# variable "http_listener_arn" {
#   type = string
# }

variable "https_listener_arn" {
  type = string
}

variable "host_name" {
  type = list(string)
}

variable "env" {
  type = string
  description = "Which environment such as dev, staging, qa or prod"
}

variable "part" {
  type = string
  description = "Which part of the application, backend or frontend"
}


variable "command" {
  description = "command for docker image"
  type = list(string)
  default = null
}

variable "volume_name" {
  type = string
  default = null
}

variable "mountPoint" {
  type = string
  default = null
}

variable "file_system_id" {
  type = string
  default = null
}

variable "access_point_id" {
  type = string
  default = null
}

variable "environment_file_s3_arn" {
  description = "S3 ARN for environment variables file (e.g. arn:aws:s3:::my-bucket/path/to/.env)"
  type        = string
  default = null
}

variable "region" {
  type = string
}

variable "env_vars" {
  type = map(string)
  default = null
}