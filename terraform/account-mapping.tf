locals {
  env = terraform.workspace
  region = {
    agentruntime-dev : "ap-southeast-1"
    agentruntime-prd : "ap-southeast-1"
  }
  account_mapping = {
    agentruntime-dev : 496367768802
    agentruntime-prd : 158711196993  
  }
}