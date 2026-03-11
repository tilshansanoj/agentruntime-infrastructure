resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = { Service = "grafana" }
}

resource "aws_service_discovery_instance" "grafana_observability" {
  service_id  = aws_service_discovery_service.grafana.id
  instance_id = "observability-ec2"

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.observability.private_ip
  }
}

resource "aws_service_discovery_service" "jaeger" {
  name = "jaeger"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = { Service = "jaeger" }
}

resource "aws_service_discovery_instance" "jaeger_observability" {
  service_id  = aws_service_discovery_service.jaeger.id
  instance_id = "observability-ec2"

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.observability.private_ip
  }
}

resource "aws_service_discovery_service" "loki" {
  name = "loki"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = { Service = "loki" }
}

resource "aws_service_discovery_instance" "loki_observability" {
  service_id  = aws_service_discovery_service.loki.id
  instance_id = "observability-ec2"

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.observability.private_ip
  }
}

resource "aws_service_discovery_service" "otel_collector" {
  name = "otel-collector"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = { Service = "otel-collector" }
}

resource "aws_service_discovery_instance" "otel_collector_observability" {
  service_id  = aws_service_discovery_service.otel_collector.id
  instance_id = "observability-ec2"

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.observability.private_ip
  }
}
