variable "efs_name" {
  type        = string
  description = "Name of the EFS filesystem"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EFS will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for mount targets"
}

variable "performance_mode" {
  type        = string
  default     = "generalPurpose"
  description = "EFS performance mode"
}

variable "throughput_mode" {
  type        = string
  default     = "elastic"
  description = "EFS throughput mode"
}

variable "vpc_cidr_block" {
  type        = list(string)
  description = "CIDR blocks allowed to access EFS"
}
