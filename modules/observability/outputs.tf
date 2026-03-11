output "instance_id" {
  description = "EC2 instance ID of the observability server"
  value       = aws_instance.observability.id
}

output "public_ip" {
  description = "Public IP address of the observability server"
  value       = aws_instance.observability.public_ip
}

output "private_ip" {
  description = "Private IP address of the observability server (use this for ECS → OTel routing)"
  value       = aws_instance.observability.private_ip
}

output "security_group_id" {
  description = "Security group ID attached to the observability server"
  value       = aws_security_group.observability_ec2.id
}

output "grafana_url" {
  description = "Grafana UI URL"
  value       = "http://${aws_instance.observability.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${aws_instance.observability.public_ip}:9090"
}

output "jaeger_url" {
  description = "Jaeger UI URL"
  value       = "http://${aws_instance.observability.public_ip}:16686"
}

output "otel_grpc_endpoint" {
  description = "OTel collector gRPC endpoint for ECS tasks (OTLP_EXPORTER_OTLP_ENDPOINT)"
  value       = "http://${aws_instance.observability.private_ip}:4317"
}

output "otel_http_endpoint" {
  description = "OTel collector HTTP endpoint for ECS tasks"
  value       = "http://${aws_instance.observability.private_ip}:4318"
}
