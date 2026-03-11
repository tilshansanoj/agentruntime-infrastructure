module "vpc" {
  source               = "./modules/vpc"
  vpc_name             = "${local.env}-${lookup(local.region, local.env)}"
  region               = lookup(local.region, local.env)
  vpc_cidr_block       = var.vpc["vpc_cidr"][terraform.workspace][lookup(local.region, local.env)][0]
  private_subnet_cidrs = var.vpc["private_subnet_cidrs"][terraform.workspace][lookup(local.region, local.env)]
  public_subnet_cidrs  = var.vpc["public_subnet_cidrs"][terraform.workspace][lookup(local.region, local.env)]

}

module "alb" {
  source           = "./modules/alb"
  public_subnet_id = [for subnet in module.vpc.public_subnets : subnet.id]
  alb_name         = "${local.env}-alb"
  region           = lookup(local.region, local.env)
  vpc_id           = module.vpc.vpc_id 
  certificate_arn  = "arn:aws:acm:ap-southeast-1:158711196993:certificate/7d47c77f-5096-475b-a575-62beba97cb80"
}

module "cluster" {
  source       = "./modules/cluster"
  cluster_name = "${local.env}-cluster"
}

module "service_discovery" {
  source                = "./modules/service-discovery"
  service_name          = local.env
  namespace_name        = "${local.env}.local"
  namespace_description = "Service discovery namespace for ECS Fargate"
  vpc_id                = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  name              = "${local.env}-postgres-db"
  storage           = 20
  db_engine         = "postgres"
  db_engine_version = "16.8"
  db_instance_class = "db.t3.micro"
  db_username       = "postgres"
  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = var.vpc["vpc_cidr"][terraform.workspace][lookup(local.region, local.env)][0]
  port              = 5432
  subnet_ids        = [for subnet in module.vpc.private_subnets : subnet.id]    
}

module "elasticache" {
  source = "./modules/elasticache"
  name = "${local.env}-redis"
  vpc_id = module.vpc.vpc_id
  vpc_cidr_blocks = [var.vpc["vpc_cidr"][terraform.workspace][lookup(local.region, local.env)][0]]
  subnet_ids = [for subnet in module.vpc.private_subnets : subnet.id]
  node_type = "cache.t3.micro"
}

module "ecr" {
  source    = "./modules/ecr"
  for_each  = var.ecr_repos
  repo_name = each.value
}

module "observability" {
  source        = "./modules/observability"
  name            = "${local.env}-observability"
  ami_id          = "ami-08d59269edddde222"
  instance_type   = "t3.small"
  subnet_id       = module.vpc.public_subnets[0].id
  aws_region      = lookup(local.region, local.env)
  environment     = "prd"
  project         = "agentruntime"
  namespace_id    = module.service_discovery.cloud_namespace_id
  vpc_id          = module.vpc.vpc_id
  disk_size       = 30
}
