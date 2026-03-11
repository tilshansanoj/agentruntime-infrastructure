variable "name" {
  description = "The name of the DB subnet group"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

# variable "db_identifier" {
#   description = "The identifier for the RDS instance"
#   type        = string
# }

variable "storage" {
  description = "The allocated storage in GB"
  type        = number
}

variable "db_engine" {
  description = "The database engine to use"
  type        = string
}

variable "db_engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class to use"
  type        = string
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
}

# variable "db_password" {
#   description = "The master password for the database"
#   type        = string
# }

variable "port" {
  description = "The DB subnet group name to associate with the database"
  type        = number
}
variable "vpc_id" {
  type = string
}
variable "vpc_cidr_block" {
  type = string
}