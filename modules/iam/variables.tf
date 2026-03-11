variable "is_root_account" {
  description = "Boolean flag to toggle between account configurations"
  type        = bool
}

variable "account_id" {
  description = "The current AWS Account ID"
  type        = string
}

variable "root_principals" {
  description = "List of ARNs for the Root account trust policy"
  type        = list(string)
  default     = []
}

variable "sub_account_principals" {
  description = "List of ARNs for the Sub-account trust policy"
  type        = list(string)
  default     = []
}

variable "backend_s3_bucket_arn" {
  description = "ARN of the S3 bucket that stores the terraform state"
  type        = string
}

variable "github_repo" {
  type = string
}