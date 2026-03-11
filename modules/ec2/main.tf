resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "${var.instance_name}-security group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "aws_key_pair" "utility-server-key" {
  key_name   =   var.key_name
  public_key =   tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "tfkey" {
content = tls_private_key.rsa.private_key_pem
filename = "tfkey"
}

resource "aws_instance" "this" {
  ami             = var.ami_id       
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = var.subnet_id
  vpc_security_group_ids = [resource.aws_security_group.ec2_sg.id]  

  associate_public_ip_address = "true"

  tags ={ 
    Name = var.instance_name 
  } 
  
}