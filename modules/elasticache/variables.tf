variable "name" {
  type = string
}

variable "vpc_cidr_blocks" {
  description = "The CIDR blocks to allow communication with Redis, typically the VPC CIDR."
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the Redis instance will be deployed."
  type        = string
}

variable "node_type" {
  description = "The instance type for the cache nodes."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to deploy the cache instance in."
  type        = list(string)
}