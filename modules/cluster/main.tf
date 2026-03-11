resource "aws_kms_key" "kms-key" {
  description             = "${var.cluster_name}-kms-key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.cluster_name}-log-group"
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms-key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.log-group.name
      }
    }
  }
}