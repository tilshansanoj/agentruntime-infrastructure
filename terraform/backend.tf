terraform {
  backend "s3" {
    bucket = "terraform-state-agentruntimelabs"
    key    = "keycloak/terraform.tfstate"
    region = "ap-southeast-1"
    assume_role = {
      role_arn = "arn:aws:iam::639935287789:role/Terraform-infra-role"
    }
  }
}