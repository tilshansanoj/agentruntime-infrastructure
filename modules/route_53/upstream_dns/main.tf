
provider "aws" {
  assume_role {
    // We assume the top-level domain is in another account
    role_arn = "arn:aws:iam::${var.account_id}:role/task-execution-role"
  }
}

data "aws_route53_zone" "base_domain" {
  name         = var.base_domain_name
  private_zone = false
}

// Record the public VPC domain NSes to the top-level domain.
resource "aws_route53_record" "nameservers" {
  name    = var.vpc_primary_domain
  type    = "NS"
  records = var.vpc_primary_domain_nameservers

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.base_domain.id
  ttl             = 172600
}

resource "aws_route53_record" "external_subdomain_zone" {
  zone_id = data.aws_route53_zone.base_domain.id
  count   = regexall("testing-\\w+", var.vpc_name_short) == true ? 0 : 1
  name    = var.vpc_primary_domain
  type    = "DS"
  ttl     = 300
  records = [var.r53_primary_zone_public_ds_record]
}
