variable "realm_id" {
  description = "The Keycloak realm identifier (e.g., agentruntime-dev)."
  type        = string
}

variable "display_name" {
  description = "Optional human-friendly display name for the realm."
  type        = string
  default     = null
}

variable "display_name_html" {
  description = "Optional HTML display name for realm login pages."
  type        = string
  default     = null
}

variable "ssl_required" {
  description = "SSL requirement mode for the realm. One of none, external, or all."
  type        = string
  default     = "external"
  validation {
    condition     = contains(["none", "external", "all"], lower(var.ssl_required))
    error_message = "ssl_required must be one of none, external, or all."
  }
}

variable "login_theme" {
  description = "Login theme to apply to the realm."
  type        = string
  default     = null
}

variable "account_theme" {
  description = "Account theme to apply to the realm."
  type        = string
  default     = null
}

variable "admin_theme" {
  description = "Admin console theme to apply to the realm."
  type        = string
  default     = null
}

variable "email_theme" {
  description = "Email theme to apply to the realm."
  type        = string
  default     = null
}

variable "smtp_server" {
  description = "Optional realm SMTP server configuration."
  type = object({
    host                  = string
    port                  = number
    from                  = string
    from_display_name     = optional(string)
    reply_to              = optional(string)
    reply_to_display_name = optional(string)
    envelope_from         = optional(string)
    ssl                   = optional(bool)
    starttls              = optional(bool)
    auth = object({
      username = string
      password = string
    })
  })
  default  = null
  nullable = true
}

variable "attributes" {
  description = "Additional attributes to set on the realm."
  type        = map(string)
  default     = {}
}

variable "frontend_url" {
  description = "Optional frontend URL Keycloak should use when constructing links (e.g., https://auth-dev.example.com)."
  type        = string
  default     = null
}

