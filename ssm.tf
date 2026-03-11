locals {
  ssm_prefix = "/${var.project}/${var.environment}/keycloak"
}

resource "aws_ssm_parameter" "kc_admin_user" {
  name        = "${local.ssm_prefix}/admin_user"
  description = "Keycloak bootstrap admin username"
  type        = "SecureString"
  value       = var.kc_admin_user

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_admin_password" {
  name        = "${local.ssm_prefix}/admin_password"
  description = "Keycloak bootstrap admin password"
  type        = "SecureString"
  value       = var.kc_admin_password

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_db_user" {
  name        = "${local.ssm_prefix}/db_user"
  description = "Keycloak Postgres username"
  type        = "SecureString"
  value       = var.kc_db_user

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_db_password" {
  name        = "${local.ssm_prefix}/db_password"
  description = "Keycloak Postgres password"
  type        = "SecureString"
  value       = var.kc_db_password

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}

resource "random_password" "kc_realm_admin_password" {
  length           = 48
  special          = true
  override_special = "!#$%^&*()-_=+[]{}:,.?"
  min_special      = 2
}

resource "aws_ssm_parameter" "kc_realm_admin_user" {
  name        = "${local.ssm_prefix}/realm_admin_user"
  description = "Service user name inside the ${var.project}-${var.environment} Keycloak realm"
  type        = "SecureString"
  value       = "${var.project}-${var.environment}-svc"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_realm_admin_password" {
  name        = "${local.ssm_prefix}/realm_admin_password"
  description = "Service user password inside the ${var.project}-${var.environment} Keycloak realm"
  type        = "SecureString"
  value       = random_password.kc_realm_admin_password.result

  lifecycle {
    ignore_changes = [ value ]
  }

  tags = local.common_tags
}

resource "random_password" "console_confidential_secret" {
  length  = 48
  special = false
}

resource "random_password" "console_platform_confidential_secret" {
  length  = 48
  special = false
}

resource "random_password" "wheelhouse_service_client_secret" {
  length  = 48
  special = false
}

resource "aws_ssm_parameter" "console_confidential_secret" {
  name        = "${local.ssm_prefix}/console_confidential_secret"
  description = "Keycloak confidential client secret for the console BFF (main realm)"
  type        = "SecureString"
  value       = random_password.console_confidential_secret.result

  lifecycle {
    ignore_changes = [ value ]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "console_platform_confidential_secret" {
  name        = "${local.ssm_prefix}/console_platform_confidential_secret"
  description = "Keycloak confidential client secret for the console sysadmin (platform realm)"
  type        = "SecureString"
  value       = random_password.console_platform_confidential_secret.result

  lifecycle {
    ignore_changes = [ value ]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "wheelhouse_service_client_secret" {
  name        = "${local.ssm_prefix}/wheelhouse_service_client_secret"
  description = "Keycloak service client secret used by Wheelhouse backend"
  type        = "SecureString"
  value       = random_password.wheelhouse_service_client_secret.result

  lifecycle {
    ignore_changes = [ value ]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_mail_username" {
  name        = "${local.ssm_prefix}/mail/username"
  description = "Keycloak SMTP username"
  type        = "SecureString"
  value       = var.kc_mail_username

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kc_mail_password" {
  name        = "${local.ssm_prefix}/mail/password"
  description = "Keycloak SMTP password or API key"
  type        = "SecureString"
  value       = var.kc_mail_password

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}
