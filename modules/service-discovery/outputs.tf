output "cloud_map_service_arn" {
  value = aws_service_discovery_service.service.arn
}

output "cloud_map_service_id" {
  value = aws_service_discovery_service.service.id
}

output "cloud_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.namespace.id
}