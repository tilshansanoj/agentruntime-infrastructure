resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name}"
}

resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  block_public_acls       = true
}

resource "aws_s3_bucket_policy" "s3_cloudfront_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.cloudfront_private_content.json
}

data "aws_iam_policy_document" "cloudfront_private_content" {
  version = "2012-10-17"

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.eventbook_distribution.arn]
    }
  }
}
