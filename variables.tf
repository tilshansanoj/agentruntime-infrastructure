variable "vpc" {
  type        = map(any)
  description = "VPC config for each environment"
  default = {
    vpc_cidr = {
      agentruntime-dev = {
        ap-southeast-1 = ["10.10.0.0/16"]
      }
      agentruntime-prd = {
        ap-southeast-1 = ["10.20.0.0/16"]
      }
    }
    private_subnet_cidrs = {
      agentruntime-dev = {
        ap-southeast-1 = ["10.10.2.0/24", "10.10.4.0/24", "10.10.6.0/24"]
      }
      agentruntime-prd = {
        ap-southeast-1 = ["10.20.2.0/24", "10.20.4.0/24", "10.20.6.0/24"]
      }
    }
    public_subnet_cidrs = {
      agentruntime-dev = {
        ap-southeast-1 = ["10.10.20.0/24", "10.10.40.0/24", "10.10.60.0/24"]
      }
      agentruntime-prd = {
        ap-southeast-1 = ["10.20.20.0/24", "10.20.40.0/24", "10.20.60.0/24"]
      }
    }
  }
}

variable "ecr_repos" {
  type = set(string)
  default = [ 
    "agentruntime-api",
    "agentruntime-keycloak", 
    "agentruntime-vault", 
    "agentruntime-wheelhouse",
    "agentruntime-bff",
    "agentruntime-control-service" 
  ]

}
variable "app_name" {
  type    = string
  default = "agentruntime"
}

# variable "db_password" {
#   type    = string
#   default = "postgres"
# }

variable "image" {
  type = string
  default = "nginx"
}