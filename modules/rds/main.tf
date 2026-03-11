
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = var.name
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage      = var.storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  identifier             = var.name
  username               = var.db_username
  password               = random_password.db_master_pwd.result
  port                   = var.port
  vpc_security_group_ids = [aws_security_group.private.id]
  db_subnet_group_name   = aws_db_subnet_group.main.id
  skip_final_snapshot    = true

  tags = {
    Name = var.name
  }
}

resource "random_password" "db_master_pwd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

// tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "primary_db" {
  name        = "${var.name}-secret"
  description = "${var.name}"
}

// We are not doing what TFSec thinks we're doing.
// tfsec:ignore:general-secrets-no-plaintext-exposure
// tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret_version" "primary_db" {
  secret_id     = aws_secretsmanager_secret.primary_db.id
  secret_string = <<EOF
{
  "uri": "postgresql://${aws_db_instance.postgres.username}:${aws_db_instance.postgres.password}@${aws_db_instance.postgres.endpoint}/${var.name}"
}
EOF
}

output "db_password" {
  value = aws_db_instance.postgres.password
  sensitive = true
}

output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

