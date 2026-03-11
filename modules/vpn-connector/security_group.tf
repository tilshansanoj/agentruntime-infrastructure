resource "aws_security_group" "Internal" {
  name        = "Internal"
  description = "Internal traffic allowance only."
  vpc_id      = var.vpc_id

#   dynamic "ingress" {
#     for_each = var.management_ingress_rules
#     content {
#       from_port   = ingress.value.from_port
#       to_port     = ingress.value.to_port
#       protocol    = ingress.value.protocol
#       cidr_blocks = ingress.value.cidr_blocks
#       description = ingress.value.description
#     }
#   }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow unfettered traffic within the VPC."
  }

  # We want our VPC to egress.
  #tfsec:ignore:aws-vpc-no-public-egress-sgr
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow unfettered outbound."
  }

  tags = {
    "Name"                   = "Internal"
  }
  lifecycle {
    ignore_changes        = [ingress] # EKS dynamically adds to this--we must eyeball changes.
    create_before_destroy = true
  }
}