terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

locals {
  kc_name = "${var.name}-keycloak"
}

resource "aws_security_group" "kc_ecs" {
  name        = "${local.kc_name}-ecs"
  description = "Security group for Keycloak ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.kc_name}-ecs" })
}

resource "aws_security_group_rule" "kc_from_main_alb" {
  type                     = "ingress"
  description              = "HTTP 8080 from main ALB"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kc_ecs.id
  source_security_group_id = var.alb_security_group_id
}

resource "aws_security_group" "kc_rds" {
  name        = "${local.kc_name}-rds"
  description = "Security group for Keycloak Postgres"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from Keycloak ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.kc_ecs.id]
  }

  tags = merge(var.tags, { Name = "${local.kc_name}-rds" })
}

module "kc_rds" {
  source = "../rds"

  name              = "kc-prod-postgres-db"
  storage           = 30
  db_engine         = "postgres"
  db_engine_version = "16.8"
  db_instance_class = "db.t3.micro"
  db_username       = "postgres"
  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = var.vpc_cidr_block
  port              = 5432
  subnet_ids        = [for subnet in module.vpc.private_subnets : subnet.id]
}

resource "aws_cloudwatch_log_group" "keycloak" {
  name              = "/ecs/${local.kc_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "random_password" "kc_realm_admin_password" { 
  length = 48
  special = true
  override_special = "!#$%^&*()-_=+[]{}:,.?"
  min_special = 2 
}

resource "random_password" "console_confidential" { 
  length = 48
  special = false
}

resource "random_password" "console_platform_confidential" { 
  length = 48
  special = false
}

resource "random_password" "wheelhouse_service_client"  { 
  length = 48
  special = false
}

resource "aws_ssm_parameter" "kc_admin_user" {
  name  = "/${var.project}/${var.environment}/keycloak/admin_user"
  type  = "SecureString"
  value = var.kc_admin_user
  lifecycle { 
    ignore_changes = [value] 
  }
  tags  = var.tags
}

resource "aws_ssm_parameter" "kc_admin_password" {
  name  = "/${var.project}/${var.environment}/keycloak/admin_password"
  type  = "SecureString"
  value = random_password.kc_realm_admin_password.result
  lifecycle { 
    ignore_changes = [value] 
  }
  tags  = var.tags
}

resource "aws_ssm_parameter" "kc_db_user" {
  name  = "/${var.project}/${var.environment}/keycloak/db_user"
  type  = "SecureString"
  value = var.db_username
  lifecycle { 
    ignore_changes = [value] 
  }
  tags  = var.tags
}

resource "aws_ssm_parameter" "kc_db_password" {
  name  = "/${var.project}/${var.environment}/keycloak/db_password"
  type  = "SecureString"
  value = module.kc_rds.db_password
  lifecycle { 
    ignore_changes = [value] 
  }
  tags  = var.tags
}

resource "aws_ssm_parameter" "kc_realm_admin_user" {
  name  = "/${var.project}/${var.environment}/keycloak/realm_admin_user"
  type  = "SecureString"
  value = var.kc_service_user
  lifecycle { 
    ignore_changes = [value] 
  }
  tags  = var.tags
}

resource "aws_ssm_parameter" "kc_realm_admin_password" {
  name  = "/${var.project}/${var.environment}/keycloak/realm_admin_password"
  type  = "SecureString"
  value = random_password.kc_realm_admin_password.result
  tags  = var.tags
}

resource "aws_ssm_parameter" "console_confidential_secret" {
  name     = "/${var.project}/${var.environment}/keycloak/console_confidential_secret"
  type     = "SecureString"
  value = random_password.console_confidential.result
  overwrite = true
  tags      = var.tags
}

resource "aws_ssm_parameter" "console_platform_confidential_secret" {
  name     = "/${var.project}/${var.environment}/keycloak/console_platform_confidential_secret"
  type     = "SecureString"
  value = random_password.console_platform_confidential.result
  overwrite = true
  tags      = var.tags
}

resource "aws_ssm_parameter" "wheelhouse_service_client_secret" {
  name     = "/${var.project}/${var.environment}/keycloak/wheelhouse_service_client_secret"
  type     = "SecureString"
  value = random_password.wheelhouse_service_client.result
  overwrite = true
  tags      = var.tags
}

data "aws_ssm_parameter" "kc_admin_user_val" { 
  name = aws_ssm_parameter.kc_admin_user.name
  with_decryption = true 
}

data "aws_ssm_parameter" "kc_admin_password_val" { 
  name = aws_ssm_parameter.kc_admin_password.name
  with_decryption = true 
}

module "kc_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.0"

  name        = local.kc_name
  cluster_arn = var.ecs_cluster_arn

  cpu           = 512
  memory = 1024
  desired_count = 1
  launch_type = "FARGATE"

  health_check_grace_period_seconds = 180
  enable_execute_command            = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.kc_ecs.id]

  task_exec_iam_role_arn    = var.ecs_task_execution_role_arn
  tasks_iam_role_arn        = var.ecs_task_role_arn
  create_task_exec_iam_role = false
  create_tasks_iam_role     = false

  load_balancer = {
    kc = {
      target_group_arn = var.keycloak_target_group_arn
      container_name   = "keycloak"
      container_port   = 8080
    }
  }

  container_definitions = {
    keycloak = {
      image                    = var.keycloak_image
      cpu                      = 512
      memory                   = 1024
      essential                = true
      readonly_root_filesystem = false
      port_mappings            = [
        { 
          name = "http" 
          containerPort = 8080
          protocol = "tcp" 
        }
      ]

      command = [
        "start",
        "--db-url=jdbc:postgresql://${module.kc_rds.db_endpoint}:5432/keycloak"
      ]

      secrets = [
        { 
          name = "KC_DB_USERNAME"   
          valueFrom = aws_ssm_parameter.kc_db_user.arn 
        },
        { 
          name = "KC_DB_PASSWORD"
          valueFrom = aws_ssm_parameter.kc_db_password.arn 
        },
        { 
          name = "KEYCLOAK_ADMIN"
          valueFrom = aws_ssm_parameter.kc_admin_user.arn 
        },
        {               
          name = "KEYCLOAK_ADMIN_PASSWORD"
          valueFrom = aws_ssm_parameter.kc_admin_password.arn 
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.keycloak.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "keycloak"
        }
      }
    }
  }
}

provider "keycloak" {
  alias     = "kc"
  url       = var.kc_frontend_url
  realm     = "master"
  username  = data.aws_ssm_parameter.kc_admin_user_val.value
  password  = data.aws_ssm_parameter.kc_admin_password_val.value
  client_id = "admin-cli"
}

module "kc_realm" {
  source   = "./keycloak-realm"
  providers = { keycloak = keycloak.kc }

  realm_id     = var.kc_realm_id
  display_name = var.kc_display_name
  frontend_url = var.kc_frontend_url
  login_theme  = var.kc_login_theme
  email_theme  = var.kc_email_theme
  attributes   = {}
}

module "kc_platform_realm" {
  source   = "./keycloak-realm"
  providers = { keycloak = keycloak.kc }

  realm_id     = var.kc_platform_realm_id
  display_name = var.kc_platform_display_name
  frontend_url = var.kc_frontend_url
  login_theme  = var.kc_login_theme
  email_theme  = var.kc_email_theme
  attributes   = {}
}

resource "keycloak_role" "platform_system_admin" {
  provider = keycloak.kc
  realm_id = var.kc_platform_realm_id
  name     = "system_admin"
  depends_on = [module.kc_platform_realm]
}

resource "keycloak_openid_client" "console_public" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = "console-public"
  name      = "Console (public)"

  enabled = true
  access_type = "PUBLIC"
  standard_flow_enabled = true
  pkce_code_challenge_method = "S256"
  full_scope_allowed = true

  root_url = var.console_root_url 
  base_url = var.console_root_url
  web_origins = [var.console_root_url]
  valid_redirect_uris = ["${var.console_root_url}/*"]
  valid_post_logout_redirect_uris = ["${var.console_root_url}/*"]

  lifecycle { prevent_destroy = true }
  depends_on = [module.kc_realm]
}

resource "keycloak_openid_client" "console_confidential" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = "console-confidential"
  name      = "Console (confidential)"

  enabled = true
  access_type = "CONFIDENTIAL"
  standard_flow_enabled = true
  direct_access_grants_enabled = true
  pkce_code_challenge_method = "S256"
  full_scope_allowed = false

  client_secret = random_password.console_confidential.result
  root_url = var.console_root_url 
  base_url = var.console_root_url
  web_origins = [var.console_root_url]
  valid_redirect_uris = ["${var.console_root_url}/*"]
  valid_post_logout_redirect_uris = ["${var.console_root_url}/*"]

  lifecycle { prevent_destroy = true }
  depends_on = [module.kc_realm]
}

resource "keycloak_openid_client" "console_platform_public" {
  provider  = keycloak.kc
  realm_id  = var.kc_platform_realm_id
  client_id = "console-platform-public"
  name      = "Console Platform (public)"

  enabled = true
  access_type = "PUBLIC"
  standard_flow_enabled = true
  pkce_code_challenge_method = "S256"
  full_scope_allowed = true

  root_url = var.console_root_url
  base_url = var.console_root_url
  web_origins = [var.console_root_url]
  valid_redirect_uris = ["${var.console_root_url}/*"]
  valid_post_logout_redirect_uris = ["${var.console_root_url}/*"]

  lifecycle { prevent_destroy = true }
  depends_on = [module.kc_platform_realm]
}

resource "keycloak_openid_client" "console_platform_confidential" {
  provider  = keycloak.kc
  realm_id  = var.kc_platform_realm_id
  client_id = "console-platform-confidential"
  name      = "Console Platform (confidential)"

  enabled = true
  access_type = "CONFIDENTIAL"
  standard_flow_enabled = true
  direct_access_grants_enabled = true
  full_scope_allowed = true

  client_secret = random_password.console_platform_confidential.result
  root_url = var.console_root_url
  base_url = var.console_root_url
  web_origins = [var.console_root_url]
  valid_redirect_uris = ["${var.console_root_url}/*"]
  valid_post_logout_redirect_uris = ["${var.console_root_url}/*"]

  lifecycle { prevent_destroy = true }
  depends_on = [module.kc_platform_realm]
}

resource "keycloak_openid_client_default_scopes" "console_platform_confidential" {
  provider       = keycloak.kc
  realm_id       = var.kc_platform_realm_id
  client_id      = keycloak_openid_client.console_platform_confidential.id
  default_scopes = ["roles", "profile", "email", "web-origins"]
}

resource "keycloak_openid_client" "wheelhouse_service" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = var.wheelhouse_service_client_id
  name      = "Wheelhouse Service Client"

  enabled = true
  access_type = "CONFIDENTIAL"
  service_accounts_enabled = true
  full_scope_allowed = true
  client_secret = random_password.wheelhouse_service_client.result

  lifecycle { prevent_destroy = true }
  depends_on = [module.kc_realm]
}

resource "keycloak_openid_client_default_scopes" "wheelhouse_service" {
  provider       = keycloak.kc
  realm_id       = var.kc_realm_id
  client_id      = keycloak_openid_client.wheelhouse_service.id
  default_scopes = ["roles", "profile", "email", "web-origins"]
}

resource "keycloak_user" "realm_service_user" {
  provider = keycloak.kc
  realm_id = var.kc_realm_id
  username = var.kc_service_user
  email    = "${var.kc_service_user}@${var.domain_name}"
  enabled  = true

  initial_password { 
    value = random_password.kc_realm_admin.result
    temporary = false 
  }
  depends_on = [module.kc_realm]
}

data "keycloak_openid_client" "realm_management" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = "realm-management"
  depends_on = [module.kc_realm]
}

data "keycloak_role" "manage_users" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "manage-users"
  depends_on = [module.kc_realm]
}

resource "keycloak_user_roles" "realm_service_roles" {
  provider = keycloak.kc
  realm_id = var.kc_realm_id
  user_id  = keycloak_user.realm_service_user.id
  role_ids = [data.keycloak_role.manage_users.id]
}

data "keycloak_openid_client_service_account_user" "wheelhouse_service" {
  provider  = keycloak.kc
  realm_id  = var.kc_realm_id
  client_id = keycloak_openid_client.wheelhouse_service.id
}

locals {
  wheelhouse_roles = ["realm-admin", "manage-users", "view-users", "query-users", "view-realm"]
}

resource "keycloak_openid_client_service_account_role" "wheelhouse_service_roles" {
  count                   = length(local.wheelhouse_roles)
  provider                = keycloak.kc
  realm_id                = var.kc_realm_id
  client_id               = data.keycloak_openid_client.realm_management.id
  service_account_user_id = data.keycloak_openid_client_service_account_user.wheelhouse_service.id
  role                    = local.wheelhouse_roles[count.index]
}
