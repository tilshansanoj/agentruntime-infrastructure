resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name        = var.namespace_name
  description = var.namespace_description
  vpc         = var.vpc_id

  tags = {
    Name = var.namespace_name
  }
}

# Create a Cloud Map service
resource "aws_service_discovery_service" "service" {
  name         = var.service_name
  namespace_id = aws_service_discovery_private_dns_namespace.namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.namespace.id
    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}