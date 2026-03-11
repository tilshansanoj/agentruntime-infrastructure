# EFS File System
resource "aws_efs_file_system" "app_efs" {
  encrypted = true
  tags = {
    Name = "${var.name}-efs"
  }
}

# Fetch the secret from Secrets Manager
data "aws_secretsmanager_secret" "n8n-secret" {
  name = "staging-n8n-service-config"
}

data "aws_secretsmanager_secret_version" "n8n-secret-version" {
  secret_id = data.aws_secretsmanager_secret.n8n-secret.id
}

# Parse the JSON secret into a map
locals {
  secret_values = jsondecode(data.aws_secretsmanager_secret_version.n8n-secret-version.secret_string)
}

# Create an EFS Access Point
resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.app_efs.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    path = "/home/node"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }
}

# EFS Mount Targets for each subnet
resource "aws_efs_mount_target" "app" {
  for_each        = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

# Security group for EFS access
resource "aws_security_group" "efs_sg" {
  name_prefix = "${var.name}-efs-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the ECS task execution IAM role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "n8n-exec-policy" {
  name   = "exec-policy-${var.name}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenDataChannel",
                "kms:Decrypt"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "n8n-ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "n8n-ecs_volume_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRolePolicyForVolumes"
}

resource "aws_iam_role_policy_attachment" "n8n-ecs_task_exec" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.n8n-exec-policy.arn
}

# Define the ECS Task Definition with EFS volume configuration
resource "aws_ecs_task_definition" "app" {
  depends_on               = [null_resource.create_database]
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    mountPoints = [{
      sourceVolume  = "efs-volume"
      containerPath = "/home/node"
    }]
    environment = [
      for key, value in local.secret_values : {
        name  = key
        value = value
      }
    ]

  }])

  volume {
    name = "efs-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.app_efs.id
      authorization_config {
        access_point_id = aws_efs_access_point.app.id
      }
      transit_encryption = "ENABLED"
    }
  }
}

# Create an ECS service to run the task definition
resource "aws_ecs_service" "app" {
  name                   = var.name
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.app.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = var.name
    container_port   = var.container_port
    target_group_arn = resource.aws_lb_target_group.app-tg.arn
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service.arn
  }
}

resource "aws_lb_target_group" "app-tg" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    interval            = 60
    timeout             = 59
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = var.listener_arn
  priority     = var.rule_priority

  action {
    type             = "forward"
    target_group_arn = resource.aws_lb_target_group.app-tg.arn
  }

  condition {
    host_header {
      values = [var.app_host]
    }
  }

}

resource "aws_route53_record" "cname_route53_record" {
  zone_id = var.zone_id
  name    = var.app_host
  type    = "CNAME"
  ttl     = "60"
  records = [var.alb_dns]
}

resource "aws_route53_record" "cname_route53_record_private" {
  zone_id = var.zone_id_private
  name    = var.app_host
  type    = "CNAME"
  ttl     = "60"
  records = [var.alb_dns]
}

# Define a security group to allow access for ECS tasks
resource "aws_security_group" "app_sg" {
  name_prefix = "${var.name}-sg"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "service" {
  name         = var.name
  namespace_id = var.namespace_id

  dns_config {
    namespace_id = var.namespace_id
    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "null_resource" "create_database" {
  provisioner "local-exec" {
    command = <<EOT
      export PGPASSWORD="${var.DB_POSTGRESDB_PASSWORD}";
      psql -h ${var.DB_HOST_internal} -p ${var.DB_POSTGRESDB_PORT} -U ${var.DB_POSTGRESDB_USER} -d postgres -c "CREATE DATABASE ${var.DB_POSTGRESDB_DATABASE};"
    EOT
  }

  triggers = {
    db_name = var.DB_POSTGRESDB_DATABASE
    db_host = var.DB_POSTGRESDB_HOST
  }
}