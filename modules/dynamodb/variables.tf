variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "ChatHistoryV2"
}

variable "environment" {
  description = "Environment tag value"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags for the DynamoDB table"
  type        = map(string)
  default     = {}
}