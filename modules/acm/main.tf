provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  assume_role {
    // We assume the top-level domain is in another account
    role_arn = "arn:aws:iam::${var.account_id}:role/Terraform-infra-role"
  }
}

# data "aws_route53_zone" "example" {
#   name         = var.vpc_primary_domain
#   private_zone = false
# }

resource "aws_acm_certificate" "acm_certificate" {
  domain_name               = var.vpc_primary_domain
  subject_alternative_names = ["*.${var.vpc_primary_domain}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "acm_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "aws_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_record : record.fqdn]
}