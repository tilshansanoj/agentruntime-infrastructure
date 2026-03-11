variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "Ubuntu 22.04 or 24.04 LTS AMI ID (cloud-init required)"

  validation {
    condition     = can(regex("^ami-[a-f0-9]+$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID (e.g. ami-0abc123def456789). Must be an Ubuntu 22.04/24.04 LTS AMI."
  }
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "disk_size" {
  type        = number
  description = "Root EBS volume size in GB"
}

variable "project" {
  type = string
  default = "agentruntime"
}

variable "environment" {
  type = string
}

variable "namespace_id" {
  type = string
}

variable "aws_region" {
  type = string  
}