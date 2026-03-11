locals {
  env = terraform.workspace
  region = {
    agentruntime-dev : "ap-southeast-1"
    agentruntime-prd : "ap-southeast-1"
    agentruntime-root : "ap-southeast-1"
  }
  account_mapping = {
    agentruntime-dev : 669200950240
    agentruntime-prd : 158711196993  
    agentruntime-root : 639935287789
  }
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}