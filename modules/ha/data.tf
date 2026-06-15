# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current region
data "aws_region" "current" {}

# Get current caller identity
data "aws_caller_identity" "current" {}

# AMI search for FortiAnalyzer BYOL
data "aws_ami" "fortianalyzer_byol" {
  count       = var.faz_license_type == "byol" ? 1 : 0
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["FortiAnalyzer-VM64-AWS *${var.faz_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# AMI search for FortiAnalyzer PAYG
data "aws_ami" "fortianalyzer_payg" {
  count       = var.faz_license_type == "payg" ? 1 : 0
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["FortiAnalyzer-VM64-AWSONDEMAND*${var.faz_version}*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get VPC information
data "aws_vpc" "selected" {
   id    = var.vpc_id
}

# Get faz1 subnet information
data "aws_subnet" "faz1" {
  id = var.subnet_ids[0]
}