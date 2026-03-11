data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket  = "terraform-state-agentruntimelabs"
    key     = "env:/${local.env}/infastructure/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
    assume_role = {
      role_arn = "arn:aws:iam::639935287789:role/Terraform-infra-role"
    }
  }
}

module "webapp" {
  source            = "../modules/fargate"

  for_each          = local.deployments
  name              = each.key
  container_port    = each.value.port
  cpu               = each.value.cpu
  memory            = each.value.memory
  public_subnet_id  = [for subnet in data.terraform_remote_state.infra.outputs.public-subnets : subnet.id]
  ingress_cidr      = data.terraform_remote_state.infra.outputs.vpc-cidr
  vpc_id            = data.terraform_remote_state.infra.outputs.vpc-id
  cluster_id        = data.terraform_remote_state.infra.outputs.cluster-id
  https_listener_arn = data.terraform_remote_state.infra.outputs.https_listener_arn  
  rule_priority     = each.value.rule_priority
  host_name         = [each.value.host_name]   
  task_count        = each.value.task_count
  image             = each.value.image
  health_check_path = each.value.health_check_path
  alb_dns           = data.terraform_remote_state.infra.outputs.alb-dns 
  alb-arn           = data.terraform_remote_state.infra.outputs.alb-arn
  env               = each.value.environment
  part              = each.value.part
  region            = local.region[terraform.workspace]
  command           = each.value.command
  env_vars          = each.value.env_vars
}
