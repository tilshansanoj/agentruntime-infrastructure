#!/bin/bash
# Bootstrap script for observability EC2 instance
# Ubuntu 22.04/24.04 LTS — installs Docker and runs OTel, Jaeger, Prometheus, Loki, Grafana.

set -euo pipefail

echo "=== Observability EC2 Bootstrap ==="
echo "Region: ${region}"
echo "Environment: ${environment}"
echo "Project: ${project}"
CLUSTER_NAME="${project}-${environment}"
SERVICE_REGEX="$${CLUSTER_NAME}|bff-${environment}|wheelhouse-${environment}|control-service-${environment}|$${CLUSTER_NAME}-keycloak"

# Ubuntu package manager
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  python3-pip

# Install Docker from the official Docker apt repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

# Keep Ansible available for optional post-provision maintenance.
pip3 install ansible

mkdir -p /opt/observability/{config/{dashboards,rules},data/{prometheus,loki,grafana,jaeger}}

cat >/opt/observability/docker-compose.yml <<'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=7d'
    restart: unless-stopped

  loki:
    image: grafana/loki:2.9.3
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./config/loki.yml:/etc/loki/local-config.yaml
      - ./config/rules:/loki/rules
      - ./data/loki:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: unless-stopped

  jaeger:
    image: jaegertracing/all-in-one:1.54
    container_name: jaeger
    ports:
      - "16686:16686"
      - "14250:14250"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
      - SPAN_STORAGE_TYPE=badger
      - BADGER_EPHEMERAL=false
      - BADGER_DIRECTORY_VALUE=/badger/data
      - BADGER_DIRECTORY_KEY=/badger/key
    volumes:
      - ./data/jaeger:/badger
    restart: unless-stopped

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.92.0
    container_name: otel-collector
    ports:
      - "4317:4317"
      - "4318:4318"
    volumes:
      - ./config/otel-config.yaml:/etc/otel-collector-config.yaml
    command: ["--config=/etc/otel-collector-config.yaml"]
    depends_on:
      - jaeger
      - prometheus
      - loki
    restart: unless-stopped

  grafana:
    image: grafana/grafana:10.2.3
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./data/grafana:/var/lib/grafana
      - ./config/grafana-datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml
      - ./config/grafana-dashboards.yml:/etc/grafana/provisioning/dashboards/dashboards.yml
      - ./config/grafana-alerts.yml:/etc/grafana/provisioning/alerting/alerts.yml
      - ./config/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=
    restart: unless-stopped

  cloudwatch-exporter:
    image: prom/cloudwatch-exporter:latest
    container_name: cloudwatch-exporter
    ports:
      - "9106:9106"
    environment:
      - AWS_REGION=${region}
    volumes:
      - ./config/cloudwatch-exporter.yml:/config.yml
    command: ["/config.yml"]
    restart: unless-stopped
EOF

cat >/opt/observability/config/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8888']

  - job_name: 'cloudwatch-exporter'
    static_configs:
      - targets: ['cloudwatch-exporter:9106']

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  - job_name: 'jaeger'
    metrics_path: /metrics
    static_configs:
      - targets: ['jaeger:14269']
EOF

# Loki config — schema v13 (v11 is deprecated in Loki 2.9+)
cat >/opt/observability/config/loki.yml <<'EOF'
auth_enabled: false
server:
  http_listen_port: 3100
ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s
schema_config:
  configs:
    - from: 2023-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
storage_config:
  tsdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks
limits_config:
  retention_period: 168h
ruler:
  storage:
    type: local
    local:
      directory: /loki/rules
  rule_path: /loki/rules
  enable_api: true
EOF

cat >/opt/observability/config/cloudwatch-exporter.yml <<'EOF'
region: ${region}
metrics:
  - aws_namespace: AWS/ECS
    aws_metric_name: CPUUtilization
    aws_dimensions: [ClusterName, ServiceName]
    aws_statistics: [Average]
  - aws_namespace: AWS/ECS
    aws_metric_name: MemoryUtilization
    aws_dimensions: [ClusterName, ServiceName]
    aws_statistics: [Average]
  - aws_namespace: AWS/ECS
    aws_metric_name: RunningTaskCount
    aws_dimensions: [ClusterName, ServiceName]
    aws_statistics: [Maximum]
EOF

cat >/opt/observability/config/otel-config.yaml <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  prometheus:
    endpoint: "0.0.0.0:8889"
  otlphttp/loki:
    endpoint: http://loki:3100/otlp/v1/logs

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlphttp/loki]
EOF

cat >/opt/observability/config/grafana-datasources.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    uid: loki
    access: proxy
    url: http://loki:3100
  - name: Jaeger
    type: jaeger
    uid: jaeger
    access: proxy
    url: http://jaeger:16686
EOF

cat >/opt/observability/config/grafana-dashboards.yml <<'EOF'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF

cat >/opt/observability/config/grafana-alerts.yml <<EOF
apiVersion: 1
groups:
  - orgId: 1
    name: prod-observability
    folder: Production
    interval: 1m
    rules:
      - uid: prod-ecs-high-cpu
        title: ECS High CPU (prod)
        condition: C
        data:
          - refId: A
            datasourceUid: prometheus
            relativeTimeRange:
              from: 900
              to: 0
            model:
              expr: avg_over_time(aws_ecs_cpuutilization_average{cluster_name="$${CLUSTER_NAME}",service_name=~"$${SERVICE_REGEX}"}[15m])
              instant: true
              refId: A
          - refId: B
            datasourceUid: __expr__
            model:
              expression: A
              type: reduce
              reducer: last
              refId: B
          - refId: C
            datasourceUid: __expr__
            model:
              expression: B
              type: threshold
              conditions:
                - evaluator:
                    type: gt
                    params: [80]
                  operator:
                    type: and
                  query:
                    params: ["C"]
                  reducer:
                    type: last
                  type: query
        noDataState: NoData
        execErrState: Error
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "CPU > 80% on prod ECS services"
EOF

cat >/opt/observability/config/dashboards/ecs-overview-prod.json <<EOF
{
  "uid": "ecs-overview-prod",
  "title": "ECS Prod Overview",
  "tags": ["ecs", "prod"],
  "schemaVersion": 38,
  "version": 1,
  "refresh": "30s",
  "panels": [
    {
      "type": "timeseries",
      "title": "ECS CPU Utilization (%)",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "aws_ecs_cpuutilization_average{cluster_name=\\"$${CLUSTER_NAME}\\",service_name=~\\"$${SERVICE_REGEX}\\"}",
          "legendFormat": "{{service_name}}"
        }
      ],
      "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 }
    },
    {
      "type": "timeseries",
      "title": "ECS Memory Utilization (%)",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "aws_ecs_memory_utilization_average{cluster_name=\\"$${CLUSTER_NAME}\\",service_name=~\\"$${SERVICE_REGEX}\\"}",
          "legendFormat": "{{service_name}}"
        }
      ],
      "gridPos": { "x": 12, "y": 0, "w": 12, "h": 8 }
    }
  ]
}
EOF

chown -R 472:472 /opt/observability/data/grafana || true
chown -R 10001:10001 /opt/observability/data/loki /opt/observability/data/jaeger || true
chown -R 65534:65534 /opt/observability/data/prometheus || true

cd /opt/observability
docker compose up -d

cat >/etc/systemd/system/observability-stack.service <<'EOF'
[Unit]
Description=Observability Stack (OTel, Jaeger, Prometheus, Loki, Grafana)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/observability
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now observability-stack.service

echo "=== Observability stack bootstrap complete ==="
