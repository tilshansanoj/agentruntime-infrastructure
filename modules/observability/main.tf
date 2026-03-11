locals {
  obs_ec2_name = "${var.name}-observability"
}

resource "aws_security_group" "observability_ec2" {
  name        = "${local.obs_ec2_name}-sg"
  description = "Security group for observability EC2 stack"
  vpc_id      = var.vpc_id

  ingress {
    description = "OTLP gRPC from ECS tasks"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "OTLP HTTP from ECS tasks"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Loki from ECS tasks"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Prometheus UI access"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana UI access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jaeger UI access"
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jaeger collector local"
    from_port   = 14250
    to_port     = 14250
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.obs_ec2_name}-sg", Service = "observability" }
}

resource "aws_iam_role" "observability_ec2" {
  name = "${local.obs_ec2_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.obs_ec2_name}-role", Service = "observability" }
}

resource "aws_iam_role_policy_attachment" "observability_ssm_core" {
  role       = aws_iam_role.observability_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "observability_cloudwatch" {
  role       = aws_iam_role.observability_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Extra permissions needed by the CloudWatch exporter to read ECS metrics.
# CloudWatchAgentServerPolicy alone does not cover cloudwatch:GetMetricStatistics
# or any ECS Describe calls required for per-service dimension filtering.
resource "aws_iam_role_policy" "observability_cloudwatch_exporter" {
  name = "${local.obs_ec2_name}-cloudwatch-exporter"
  role = aws_iam_role.observability_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchExporterMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSDescribe"
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:ListTasks",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "observability_ec2" {
  name = "${local.obs_ec2_name}-profile"
  role = aws_iam_role.observability_ec2.name
}

resource "aws_instance" "observability" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.observability_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.observability_ec2.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.disk_size
    encrypted             = true
    delete_on_termination = true
  }

}
resource "aws_ssm_parameter" "observability_instance_id" {
  name  = "/${var.project}/${var.environment}/observability/instance_id"
  type  = "String"
  value = aws_instance.observability.id

  tags = { Name = local.obs_ec2_name, Service = "observability" }
}
