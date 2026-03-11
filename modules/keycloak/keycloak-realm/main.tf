terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.2.0"
    }
  }
}

locals {
  merged_attributes = merge(
    var.attributes,
    var.display_name != null ? { "displayName" = var.display_name } : {},
    var.frontend_url != null ? { "frontendUrl" = var.frontend_url } : {}
  )
}

resource "keycloak_realm" "this" {
  realm             = var.realm_id
  enabled           = true
  display_name_html = var.display_name_html
  ssl_required      = var.ssl_required
  login_theme       = var.login_theme
  account_theme     = var.account_theme
  admin_theme       = var.admin_theme
  email_theme       = var.email_theme
  attributes        = local.merged_attributes

  dynamic "smtp_server" {
    for_each = var.smtp_server == null ? [] : [var.smtp_server]
    content {
      host                  = smtp_server.value.host
      port                  = tostring(smtp_server.value.port)
      from                  = smtp_server.value.from
      from_display_name     = try(smtp_server.value.from_display_name, null)
      reply_to              = try(smtp_server.value.reply_to, null)
      reply_to_display_name = try(smtp_server.value.reply_to_display_name, null)
      envelope_from         = try(smtp_server.value.envelope_from, null)
      ssl                   = try(smtp_server.value.ssl, null)
      starttls              = try(smtp_server.value.starttls, null)

      auth {
        username = smtp_server.value.auth.username
        password = smtp_server.value.auth.password
      }
    }
  }

  lifecycle {
    ignore_changes = [attributes]
  }
}

