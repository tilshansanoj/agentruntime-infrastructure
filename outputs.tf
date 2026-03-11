output "alb-dns" {
  description = "ALB DNS endpoint"
  value       = module.alb.alb-dns
}

output "vpc-id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc-cidr" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private-subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public-subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "cluster-id" {
  description = "The ID of the load balancer"
  value       = module.cluster.id
}

output "alb-arn" {
  description = "The ARN of the load balancer"
  value       = module.alb.alb-arn
}

output "http_listener_arn" {
  description = "The ARN of the load balancer listner"
  value       = module.alb.http_listener_arn
}

output "https_listener_arn" {
  description = "The ARN of the load balancer listner"
  value       = module.alb.https_listener_arn
}

# output "zone-id" {
#   description = "route 53 zone id"
#   value       = module.dns.zone_id
# }

# output "zone-id-private" {
#   description = "route 53 zone id"
#   value       = module.dns.zone_id_private
# }

# output "vpc-primary-domain" {
#   description = "pimary domain"
#   value       = var.dns["vpc_primary_domain"][terraform.workspace][lookup(local.region, local.env)]
# }