data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_secretsmanager_secret" "openvpn_connector_profile" {
  arn = var.secret_manager_arn
}

data "aws_secretsmanager_secret_version" "openvpn_connector_profile" {
  secret_id = data.aws_secretsmanager_secret.openvpn_connector_profile.id
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_key
}

resource "aws_iam_role" "openvpn_connector" {
  name = "OpenVPN-Connector-${var.name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

// tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "openvpn_connector_route_manager_policy" {
  name = "OpenVPNConnectorRouteManagerPolicy${var.name}"
  role = aws_iam_role.openvpn_connector.id

  policy = <<-EOD
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:CreateRoute",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeRouteTables",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:ReplaceRoute",
                "ec2:DeleteRoute"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2messages:GetMessages",
                "ssm:UpdateInstanceInformation",
                "ssm:ListInstanceAssociations",
                "ssm:ListAssociations",
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
  EOD
}

// Required for SSM session management / daemon access
resource "aws_iam_role_policy_attachment" "openvpn_connector" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.openvpn_connector.id
}

// Convert our IAM role to an instance profile
resource "aws_iam_instance_profile" "openvpn_connector" {
  name = "OpenVPN-Connector-${var.name}"
  role = aws_iam_role.openvpn_connector.name
}

resource "aws_instance" "openvpn_connector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  iam_instance_profile   = aws_iam_instance_profile.openvpn_connector.name
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.Internal.id]
  source_dest_check      = false
  subnet_id              = var.public_subnet_id
  ebs_optimized          = true
  monitoring             = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }



  user_data = <<EOF
#!/bin/bash -e
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
apt update
apt install -y curl python3-pip openvpn
apt-get -y dist-upgrade
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p
IF=$(ip route | grep default | awk '{print $5}')
iptables -t nat -A POSTROUTING -o $IF -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o $IF -j MASQUERADE
DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
echo '${data.aws_secretsmanager_secret_version.openvpn_connector_profile.secret_string}' > /etc/openvpn/connector.conf
hostnamectl set-hostname ${var.name}-openvpn-connector.${var.vpc_primary_domain}
systemctl enable --now openvpn@connector
EOF

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-OpenVPN-Connector"
  }

  volume_tags = {
    Name = "${var.name}-OpenVPN-Connector"
  }
}

resource "aws_eip" "openvpn_connector" {
  instance = aws_instance.openvpn_connector.id
  domain   = "vpc"
}

resource "aws_route53_record" "openvpn_connector_internal" {
  zone_id = var.zone_id_private
  name    = "vpn.${var.vpc_primary_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_instance.openvpn_connector.private_dns]
}

// Dropping the record into the top-level zone--this is likely not going to work long term.
resource "aws_route53_record" "openvpn_connector_external" {
  zone_id = var.zone_id_public
  name    = "vpn.${var.vpc_primary_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_instance.openvpn_connector.public_dns]
}