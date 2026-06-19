##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################
# locals
##############################################################################################################
locals {
  faz1_name = "${var.prefix}-faz1"
  faz1_vars = {
    faz_vm_name           = local.faz1_name
    faz_admin_port        = var.faz_admin_port
    faz_license_file      = var.faz1_byol_license_file
    faz_license_fortiflex = var.faz1_byol_fortiflex_license_token
    peer_ipaddr           = aws_network_interface.faz2.private_ip
    peer_serial_number    = var.faz2_byol_serial_number
    ha_priority           = 100
    ha_preferred_role     = "primary"
    ha_password           = var.ha_password
    ha_ipaddr             = var.ha_mode == "a-a" ? "" : (var.ha_mode == "a-p" && var.ha_ip == "public" ? aws_eip.vip[0].public_ip : cidrhost(data.aws_subnet.faz1.cidr_block, 100))
    ha_group_id           = var.ha_group_id
    ha_group_name         = var.ha_group_name
    initial_sync          = "enable"
    ha_mode               = var.ha_mode
  }

  faz2_name = "${var.prefix}-faz2"
  faz2_vars = {
    faz_vm_name           = local.faz2_name
    faz_admin_port        = var.faz_admin_port
    faz_license_file      = var.faz2_byol_license_file
    faz_license_fortiflex = var.faz2_byol_fortiflex_license_token
    peer_ipaddr           = aws_network_interface.faz1.private_ip
    peer_serial_number    = var.faz1_byol_serial_number
    ha_priority           = 1
    ha_preferred_role     = "secondary"
    ha_password           = var.ha_password
    ha_ipaddr             = var.ha_mode == "a-a" ? "" : (var.ha_mode == "a-p" && var.ha_ip == "public" ? aws_eip.vip[0].public_ip : cidrhost(data.aws_subnet.faz1.cidr_block, 100))
    ha_group_id           = var.ha_group_id
    ha_group_name         = var.ha_group_name
    initial_sync          = "disable"
    ha_mode               = var.ha_mode
  }

  # AMI ID selection based on license type
  ami_id = var.faz_license_type == "byol" ? (
    length(data.aws_ami.fortianalyzer_byol) > 0 ? data.aws_ami.fortianalyzer_byol[0].id : null
    ) : (
    length(data.aws_ami.fortianalyzer_payg) > 0 ? data.aws_ami.fortianalyzer_payg[0].id : null
  )

  # User data for initialization
  faz1_user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", local.faz1_vars))
  faz2_user_data = base64encode(templatefile("${path.module}/templates/user_data.tpl", local.faz2_vars))

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
    },
    {
      from_port   = 5199
      to_port     = 5199
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "FAZ HA"
    },
    {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  ]

  faz1_tags = merge(var.fortinet_tags, {
    Name = local.faz1_name
  })
  faz2_tags = merge(var.fortinet_tags, {
    Name = local.faz2_name
  })
}

##############################################################################################################
# Security group for FortiAnalyzer
##############################################################################################################
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
    Name = "${var.prefix}-security-group"
  })
}

##############################################################################################################
# Elastic IPs
##############################################################################################################
resource "aws_eip" "faz1" {
  count = (var.ha_mode == "a-a" || (var.ha_mode == "a-p" && var.ha_ip == "public")) ? 1 : 0

  domain            = "vpc"
  network_interface = aws_network_interface.faz1.id

  depends_on = [aws_instance.faz1]

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-faz1-eip"
  })
}

resource "aws_eip" "faz2" {
  count = (var.ha_mode == "a-a" || (var.ha_mode == "a-p" && var.ha_ip == "public")) ? 1 : 0

  domain            = "vpc"
  network_interface = aws_network_interface.faz2.id

  depends_on = [aws_instance.faz2]

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-faz2-eip"
  })
}

resource "aws_eip" "vip" {
  count = (var.ha_ip == "public" && var.ha_mode == "a-p") ? 1 : 0

  domain = "vpc"

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-eip"
  })
}

##############################################################################################################
# EC2 Instances
##############################################################################################################
# Network interface for FortiAnalyzer 1
resource "aws_network_interface" "faz1" {
  subnet_id       = var.subnet_ids[0]
  security_groups = [aws_security_group.fortianalyzer.id]
  private_ip_list_enabled = true
    private_ip_list = (
    var.ha_mode == "a-a" ? [] :
    (var.ha_mode == "a-p" && var.ha_ip == "private") ? [cidrhost(data.aws_subnet.faz1.cidr_block, 50), local.faz1_vars.ha_ipaddr] :
    []
  )
  tags = merge(var.fortinet_tags, {
    Name = "${local.faz1_name}-nic1"
  })
}

# Additional EBS volume for log storage
resource "aws_ebs_volume" "faz1_logs" {
  count = var.enable_log_volume ? 1 : 0

  availability_zone = var.subnet_availability_zones[0]
  size              = var.faz_log_volume_size
  type              = var.faz_log_volume_type
  encrypted         = true

  tags = merge(local.faz1_tags, {
    Name = "${var.prefix}-faz1-log-volume"
  })
}

# Attach log volume to instance
resource "aws_volume_attachment" "faz1_logs" {
  count = var.enable_log_volume ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.faz1_logs[0].id
  instance_id = aws_instance.faz1.id
}

# FortiAnalyzer 1 EC2 instance
resource "aws_instance" "faz1" {
  ami           = local.ami_id
  instance_type = var.faz_vmsize
  key_name      = var.key_name

  availability_zone = var.subnet_availability_zones[0]

  # Network configuration
  primary_network_interface {
    network_interface_id = aws_network_interface.faz1.id
  }

  # Root volume configuration
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.faz_root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.fortinet_tags, {
      Name = "${var.prefix}-faz1-root-volume"
    })
  }

  # IAM instance profile
  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.fortianalyzer[0].name : null

  # User data for initial configuration
  user_data_base64 = local.faz1_user_data

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Termination protection
  disable_api_termination = var.enable_termination_protection

  # Instance metadata options
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = merge(local.faz1_tags, {
    Name = local.faz1_name
  })

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

# Network interface for FortiAnalyzer 2
resource "aws_network_interface" "faz2" {
  subnet_id       = (var.ha_mode == "a-p" && var.ha_ip == "private") ? var.subnet_ids[0] : var.subnet_ids[1]
  security_groups = [aws_security_group.fortianalyzer.id]

  tags = merge(var.fortinet_tags, {
    Name = "${local.faz2_name}-nic1"
  })
}

# Additional EBS volume for log storage
resource "aws_ebs_volume" "faz2_logs" {
  count = var.enable_log_volume ? 1 : 0

 availability_zone  = (var.ha_mode == "a-p" && var.ha_ip == "private") ? var.subnet_availability_zones[0] : var.subnet_availability_zones[1]
  size              = var.faz_log_volume_size
  type              = var.faz_log_volume_type
  encrypted         = true

  tags = merge(local.faz2_tags, {
    Name = "${var.prefix}-faz2-log-volume"
  })
}

# Attach log volume to instance
resource "aws_volume_attachment" "faz2_logs" {
  count = var.enable_log_volume ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.faz2_logs[0].id
  instance_id = aws_instance.faz2.id
}

# FortiAnalyzer 2 EC2 instance
resource "aws_instance" "faz2" {
  ami           = local.ami_id
  instance_type = var.faz_vmsize
  key_name      = var.key_name

  availability_zone = (var.ha_mode == "a-p" && var.ha_ip == "private") ? var.subnet_availability_zones[0] : var.subnet_availability_zones[1]

  # Network configuration
  primary_network_interface {
    network_interface_id = aws_network_interface.faz2.id
  }

  # Root volume configuration
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.faz_root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.fortinet_tags, {
      Name = "${var.prefix}-faz2-root-volume"
    })
  }

  # IAM instance profile
  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.fortianalyzer[0].name : null

  # User data for initial configuration
  user_data_base64 = local.faz2_user_data

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Termination protection
  disable_api_termination = var.enable_termination_protection

  # Instance metadata options
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = merge(local.faz2_tags, {
    Name = local.faz2_name
  })

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

##############################################################################################################
# IAM
##############################################################################################################
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
          "ec2:AssignPrivateIpAddresses",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAddresses",
          "ec2:AssociateAddress",
          "ec2:CreateTags",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}
