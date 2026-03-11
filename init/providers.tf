provider "aws" {
  region = lookup(local.region, local.env)
}