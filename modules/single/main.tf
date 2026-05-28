##############################################################################################################
#
# FortiAnalyzer - a standalone FortiAnalyzer VM
# Terraform deployment template for AWS
#
##############################################################################################################
# locals
##############################################################################################################
locals {
  faz_name = "${var.prefix}-faz"
  # AMI ID selection based on license type
  ami_id = var.faz_license_type == "byol" ? (
    length(data.aws_ami.fortianalyzer_byol) > 0 ? data.aws_ami.fortianalyzer_byol[0].id : null
  ) : (
    length(data.aws_ami.fortianalyzer_payg) > 0 ? data.aws_ami.fortianalyzer_payg[0].id : null
  )

  faz_vars = {
    faz_vm_name           = local.faz_name
    faz_admin_port        = var.faz_admin_port
    faz_license_file      = var.faz_byol_license_file
    faz_license_fortiflex = var.faz_byol_fortiflex_license_token
    faz_username          = var.username
    faz_ssh_public_key    = var.faz_ssh_public_key_file
  }

  # User data for initialization
  user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", local.faz_vars))

  # Security group rules
  management_ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr
      description = "HTTPS management access"
    },
    {
      from_port   = 541
      to_port     = 541
      protocol    = "tcp"
      cidr_blocks = var.fortigate_cidr
      description = "FortiGate to FortiAnalyzer secure log transmission"
    },
    {
      from_port   = 514
      to_port     = 514
      protocol    = "udp"
      cidr_blocks = var.fortigate_cidr
      description = "Syslog reception"
    }
  ]

  faz_tags = merge(var.fortinet_tags, {
    Name        = local.faz_name
    Environment = "production"
  })
}

# Security group for FortiAnalyzer
resource "aws_security_group" "fortianalyzer" {
  name_prefix = "${var.prefix}-sg"
  description = "Security group for FortiAnalyzer ${var.prefix}"
  vpc_id      = var.vpc_id

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = local.management_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.fortinet_tags, {
    Name = "${local.faz_name}-security-group"
  })
}

# Network interface for FortiAnalyzer
resource "aws_network_interface" "fortianalyzer_mgmt" {
  subnet_id       = var.subnet_id
  private_ips     = var.private_ip != "" ? [var.private_ip] : null
  security_groups = [aws_security_group.fortianalyzer.id]

  tags = merge(var.fortinet_tags, {
    Name = "${local.faz_name}-nic1"
  })
}

# Elastic IP for management interface
resource "aws_eip" "fortianalyzer" {
  count = var.create_public_ip ? 1 : 0

  domain            = "vpc"
  network_interface = aws_network_interface.fortianalyzer_mgmt.id

  depends_on = [aws_instance.fortianalyzer]

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-eip"
  })
}

# Additional EBS volume for log storage
resource "aws_ebs_volume" "fortianalyzer_logs" {
  count = var.enable_log_volume ? 1 : 0

  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
  size              = var.faz_log_volume_size
  type              = var.faz_log_volume_type
  encrypted         = true

  tags = merge(local.faz_tags, {
    Name = "${var.prefix}-log-volume"
  })
}

# FortiAnalyzer EC2 instance
resource "aws_instance" "fortianalyzer" {
  ami           = local.ami_id
  instance_type = var.faz_vmsize
  key_name      = var.key_name

  availability_zone = var.availability_zone

  # Network configuration
  primary_network_interface {
    network_interface_id = aws_network_interface.fortianalyzer_mgmt.id
  }

  # Root volume configuration
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.faz_root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.fortinet_tags, {
      Name = "${var.prefix}-root-volume"
    })
  }

  # IAM instance profile
  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.fortianalyzer[0].name : null

  # User data for initial configuration
  user_data_base64 = local.user_data

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Termination protection
  disable_api_termination = var.enable_termination_protection

  # Instance metadata options
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.faz_tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

# Attach log volume to instance
resource "aws_volume_attachment" "fortianalyzer_logs" {
  count = var.enable_log_volume ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.fortianalyzer_logs[0].id
  instance_id = aws_instance.fortianalyzer.id
}

# IAM role for FortiAnalyzer
resource "aws_iam_role" "fortianalyzer" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.prefix}-faz-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-faz-role"
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "fortianalyzer" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.prefix}-faz-instance-profile"
  role = aws_iam_role.fortianalyzer[0].name

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-faz-instance-profile"
  })
}

# IAM policy for FortiAnalyzer
resource "aws_iam_role_policy" "fortianalyzer" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.prefix}-faz-policy"
  role = aws_iam_role.fortianalyzer[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}
