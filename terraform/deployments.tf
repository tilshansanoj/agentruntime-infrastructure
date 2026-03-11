locals {
  deployments = {
    agentruntime-keycloak-prd = {
      port              = 8080
      cpu               = 512
      memory            = 1024
      rule_priority     = 420
      task_count        = 1
      image             = "158711196993.dkr.ecr.ap-southeast-1.amazonaws.com/agentruntime-keycloak:latest"
      host_name         = "auth.agentruntime.io"
      health_check_path = "/health"
      command = [
        "start",
        "--db-url=jdbc:postgresql://agentruntime-prd-postgres-db.czy6i4q0c1pm.ap-southeast-1.rds.amazonaws.com:5432/keycloak"
      ]
      environment       = "prd"
      env_vars = {
        KC_HTTP_MANAGEMENT_HEALTH_ENABLED="false"
        KC_HOSTNAME_STRICT="false"
        KC_HOSTNAME="auth.agentruntime.io"
        KC_DB_USERNAME="postgres"
        KC_DB_PASSWORD="_4t}Jkd?#Kip_UJY" 
        KC_BOOTSTRAP_ADMIN_USERNAME= "admin"
        KC_BOOTSTRAP_ADMIN_PASSWORD= "6E2E9y{K£0'f"
      }
      part              = "keycloak"
    }
  }
}


# locals {
#   deployments = {
#     eventbook-ai-dev = {
#       port              = 8000
#       cpu               = 512
#       memory            = 1024
#       rule_priority     = 440
#       task_count        = 1
#       image             = "496367768802.dkr.ecr.us-east-1.amazonaws.com/eventbook-ai:latest"
#       host_name         = "ai.dev.eventbook.ai"
#       health_check_path = "/"
#       environment       = "dev"
#       part              = "ai-platform"
#     }
#   }
# }
