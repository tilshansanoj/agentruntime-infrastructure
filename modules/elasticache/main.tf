resource "aws_security_group" "redis_sg" {
  name        = "${var.name}-sg"
  description = "Allow Redis communication within VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.name}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Redis subnet group"
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.name}"
  description          = "${var.name} replication group for bullmq redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_clusters   = 1
  port                 = 6379

  parameter_group_name = aws_elasticache_parameter_group.redis.name


  # Multi-AZ and Auto-failover Disabled
  multi_az_enabled           = false
  automatic_failover_enabled = false

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  # Data tiering disabled
  data_tiering_enabled = false

  # Use the security group
  security_group_ids = [aws_security_group.redis_sg.id]
  subnet_group_name  = aws_elasticache_subnet_group.redis.name

}

resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.name}-parameter-group"
  family      = "redis7"
  description = "Custom parameter group for Redis with noeviction policy"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}
