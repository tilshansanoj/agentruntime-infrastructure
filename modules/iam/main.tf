data "aws_caller_identity" "current" {}

locals {
  active_principals = distinct(concat(
    var.is_root_account ? var.root_principals : var.sub_account_principals,
    [data.aws_caller_identity.current.arn]
  ))
}

resource "aws_iam_role" "infra_role" {
  name                 = "Terraform-infra-role"
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = local.active_principals
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "infra_s3_full" {
  role       = aws_iam_role.infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "infra_admin_access" {
  count      = var.is_root_account ? 0 : 1
  role       = aws_iam_role.infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "state_access_policy" {
  name = var.is_root_account ? "terraform-state-access-policy" : "terraform-state-s3-bucket-policy"
  role = aws_iam_role.infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "Statement1"
      Effect   = "Allow"
      Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      Resource = [
        "${var.backend_s3_bucket_arn}",
        "${var.backend_s3_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role" "github_oidc_role" {
  name                 = "github-oidc-role"
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}/*" }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_oidc_s3_full" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


