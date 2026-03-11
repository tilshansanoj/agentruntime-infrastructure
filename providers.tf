provider "aws" {
  region = lookup(local.region, local.env)
  assume_role {
    role_arn = "arn:aws:iam::${lookup(local.account_mapping, local.env)}:role/Terraform-infra-role"
  }
}