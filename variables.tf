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

variable "image" {
  type = string
  default = "nginx"
}

variable "project" {
  description = "Project name used as SSM path prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. prod)"
  type        = string
}

variable "kc_admin_user" {
  description = "Keycloak bootstrap admin username (KEYCLOAK_ADMIN)"
  type        = string
  sensitive   = true
}

variable "kc_admin_password" {
  description = "Keycloak bootstrap admin password (KEYCLOAK_ADMIN_PASSWORD)"
  type        = string
  sensitive   = true
}

variable "kc_db_user" {
  description = "Postgres master username for the Keycloak database"
  type        = string
  sensitive   = true
}

variable "kc_db_password" {
  description = "Postgres master password for the Keycloak database"
  type        = string
  sensitive   = true
}
variable "kc_mail_username" {
  description = "SMTP username for Keycloak outbound email"
  type        = string
  sensitive   = true
}

variable "kc_mail_password" {
  description = "SMTP password or API key for Keycloak outbound email"
  type        = string
  sensitive   = true
}

