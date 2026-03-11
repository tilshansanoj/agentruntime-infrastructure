variable "name"        { type = string }
variable "project"     { type = string }
variable "environment" { type = string }
variable "aws_region"  { type = string }
variable "domain_name" { type = string }

variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "ecs_cluster_arn"             { type = string }
variable "ecs_task_execution_role_arn" { type = string }
variable "ecs_task_role_arn"           { type = string }
variable "alb_security_group_id"       { type = string }
variable "keycloak_target_group_arn"   { type = string }

variable "db_username"       { type = string }
variable "db_password" { 
    type = string
    sensitive = true
  }
variable "rds_instance_class" { type = string }

variable "keycloak_image" {
  description = "Full ECR image URI for Keycloak"
  type        = string
}

variable "kc_frontend_url"         { type = string }
variable "kc_realm_id"             { type = string }
variable "kc_display_name"         { type = string }
variable "kc_platform_realm_id"    { type = string }
variable "kc_platform_display_name" { type = string }
variable "kc_service_user"         { type = string }
variable "kc_login_theme"          { type = string }
variable "kc_email_theme"          { type = string }
variable "console_root_url"        { type = string }
variable "wheelhouse_service_client_id" { type = string }

variable "keycloak_realm_module_path" {
  description = "Path to a keycloak-realm child module"
  type        = string
}

variable "tags" { type = map(string) }

variable "kc_admin_user" {
  description = "Keycloak admin username"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type = string
}