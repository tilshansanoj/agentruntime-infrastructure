data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "exec-policy" {

  name   = "exec-policy-${var.name}-${var.env}"
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
                "logs:CreateLogGroup",
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

resource "aws_iam_policy" "secretsmanager-policy" {

  name   = "secretsmanager-policy-${var.name}-${var.env}"
  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "${var.name}-${var.env}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_tasks_s3_access_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = aws_iam_policy.exec-policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_secretmanager" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = aws_iam_policy.secretsmanager-policy.arn
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.name}-${var.env}-log-group"
}

resource "aws_ecs_task_definition" "taskdefinition" {
  cpu                = var.cpu
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_tasks_execution_role.arn

  family                   = "${var.name}-tasks"
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  dynamic "volume" {
  for_each = var.volume_name != null ? [1] : []

    content {
      name = var.volume_name
      efs_volume_configuration {
        file_system_id     = var.file_system_id
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = var.access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }
  
  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image
    cpu       = var.cpu
    memory    = var.memory
    memoryReservation = var.memory
    essential = true
    command          = var.command != null ? var.command : []

    portMappings = [{
      name = "${var.name}-${var.container_port}-tcp"
      containerPort = var.container_port
      hostPort = var.container_port
      protocol = "tcp"
      appProtocol = "http"
    }]

    environment = var.env_vars != null ? [
      for key, value in var.env_vars :
      {
        name  = key
        value = value
      }
    ] : []
    
    environmentFiles = var.environment_file_s3_arn != null ? [{
      value = var.environment_file_s3_arn
      type  = "s3"
    }] : []

    mountPoints = var.volume_name != null ? [{
      sourceVolume  = var.volume_name
      containerPath = var.mountPoint
      readOnly      = false
    }] : []

    logConfiguration = {
      logDriver = "awslogs",
      options = {
          awslogs-group = aws_cloudwatch_log_group.log-group.name,
          mode = "non-blocking",
          awslogs-create-group = "true",
          max-buffer-size = "25m",
          awslogs-region = var.region,
          awslogs-stream-prefix = "ecs"
      }
    }
  }])
  
}

resource "aws_security_group" "app-sg" {
  name_prefix = "app-sg-"
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

resource "aws_lb_target_group" "app-tg" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    interval            = 60
    timeout             = 59
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  lifecycle {
      create_before_destroy = true
      ignore_changes        = [name] 
  }
}
resource "aws_lb_listener_rule" "host_based" {
  listener_arn = var.https_listener_arn
  priority     = var.rule_priority

  condition {
    host_header {
      values = var.host_name
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn
  }
}


resource "aws_ecs_service" "ecs-service" {
  cluster                = var.cluster_id
  desired_count          = var.task_count
  launch_type            = "FARGATE"
  name                   = "${var.name}-service"
  task_definition        = resource.aws_ecs_task_definition.taskdefinition.arn
  enable_execute_command = true
  force_new_deployment   = true

  lifecycle {
    ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
  }

  load_balancer {
    container_name   = var.name
    container_port   = var.container_port
    target_group_arn = resource.aws_lb_target_group.app-tg.arn
  }

  network_configuration {
    security_groups  = [resource.aws_security_group.app-sg.id]
    subnets          = var.public_subnet_id
    assign_public_ip = true
  }
}
