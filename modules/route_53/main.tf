provider "aws" {
  alias  = "ap-southeast-1"
  region = "ap-southeast-1"

}

resource "aws_route53_zone" "primary" {
  name    = var.vpc_primary_domain
  comment = "${var.vpc_primary_domain} primarily used for ${var.enviroment}"

  vpc {
    vpc_id = var.vpc_id
  }
  // checkov:skip=CKV2_AWS_38:This is not a public zone and cannot have DNSSEC.
  // checkov:skip=CKV2_AWS_39:You cannot create query logging for a private zone.
}

resource "aws_route53_zone" "primary_external" {
  name    = var.vpc_primary_domain
  comment = "${var.vpc_primary_domain} primarily used for ${var.enviroment} :: Internet-facing!"
}

resource "aws_cloudwatch_log_group" "primary_external" {
  provider          = aws.us-east-1
  name              = "/aws/route53/${var.vpc_primary_domain}"
  kms_key_id        = aws_kms_key.cloudwatch_query_logs.arn
  retention_in_days = 365
}

data "aws_iam_policy_document" "route53-query-logging-policy" {
  statement {
    actions = [
      "logs:*",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]

    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}

// Create Needed KMS Keys
resource "aws_kms_key" "cloudwatch_query_logs" {
  provider            = aws.us-east-1
  description         = "KMS Key for CloudWatch R53 Query Logs"
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true
  policy              = <<EOT
{
    "Version": "2012-10-17",
    "Id": "${var.enviroment}-key",
    "Statement": [
        {
            "Sid": "${var.vpc_name_short} Log Group Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.us-east-1.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt*",
                "kms:Decrypt*",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "ArnEquals": {
                    "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:us-east-1:${var.account_id}:log-group:/aws/route53/*"
                }
            }
        }
    ]
}
EOT

  tags = {
    "Name" = "KMS Key for ${var.enviroment} R53 Query Log Encryption"
  }
}

// Alias our KMS Keys for Easier Identification
resource "aws_kms_alias" "cloudwatch_query_logs" {
  provider      = aws.us-east-1
  name          = "alias/${lower(var.enviroment)}-R53-Query-Logs-KMS-Key"
  target_key_id = aws_kms_key.cloudwatch_query_logs.key_id
}

resource "aws_route53_query_log" "primary_external" {
  provider                 = aws.us-east-1
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.primary_external.arn
  zone_id                  = aws_route53_zone.primary_external.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53-query-logging-policy]
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  provider        = aws.us-east-1
  policy_document = data.aws_iam_policy_document.route53-query-logging-policy.json
  policy_name     = "route53-query-logging-policy"
}

resource "aws_kms_key" "external_subdomain_zone" {
  provider                 = aws.us-east-1
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "${var.vpc_name_short} Allow Route 53 DNSSEC Service",
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
          }
        }
      },
      {
        Action = "kms:CreateGrant",
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Resource = "*"
        Sid      = "${var.vpc_name_short} Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_route53_key_signing_key" "external_subdomain_zone" {
  provider                   = aws.us-east-1
  hosted_zone_id             = aws_route53_zone.primary_external.id
  key_management_service_arn = aws_kms_key.external_subdomain_zone.arn
  name                       = "${var.vpc_primary_domain}-DNSSEC"
}

// Alias our KMS Keys for Easier Identification
resource "aws_kms_alias" "external_subdomain_zone" {
  provider      = aws.us-east-1
  name          = "alias/${lower(var.enviroment)}-PubSubDomain"
  target_key_id = aws_kms_key.external_subdomain_zone.key_id
}

resource "aws_route53_hosted_zone_dnssec" "external_subdomain_zone" {
  hosted_zone_id = aws_route53_key_signing_key.external_subdomain_zone.hosted_zone_id

  depends_on = [
    aws_route53_key_signing_key.external_subdomain_zone
  ]
}

module "upstream_dns" {
  source = "./upstream_dns"

  base_domain_name                  = var.base_domain_name
  r53_primary_zone_public_ds_record = aws_route53_key_signing_key.external_subdomain_zone.ds_record
  vpc_primary_domain                = var.vpc_primary_domain
  vpc_primary_domain_nameservers    = aws_route53_zone.primary_external.name_servers
  vpc_name_short                    = var.vpc_name_short
  account_id                        = var.account_id
}