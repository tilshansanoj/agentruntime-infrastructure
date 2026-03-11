resource "aws_efs_file_system" "efs" {
  creation_token = var.efs_name
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = true
  tags = {
    Name = var.efs_name
  }
}

resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_block
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}