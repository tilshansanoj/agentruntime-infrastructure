resource "random_string" "origin_id" {
  length  = 16
  special = false
  upper   = true
  numeric = true
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "eventbook_distribution" {
  enabled         = true
  is_ipv6_enabled = false
  comment         = ""
  price_class     = "PriceClass_All"
  staging         = false
  http_version    = "http2"
  aliases         = ["${var.domain_name}"]

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_domain_name
    origin_id   = "${aws_s3_bucket.bucket.bucket_domain_name}-${random_string.origin_id.result}"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id

    origin_path = ""

    connection_attempts = 3
    connection_timeout  = 10
  }

  default_root_object = "/index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "${aws_s3_bucket.bucket.bucket_domain_name}-${random_string.origin_id.result}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl               = 0
    compress               = true

    # Using the cache policy ID from the CloudFormation template
    cache_policy_id = "${var.cache_policy_id}"
    
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.certificate_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  tags = {
    Name = "${var.name}-cloudfront-distribution"
  }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.eventbook_distribution.domain_name
}