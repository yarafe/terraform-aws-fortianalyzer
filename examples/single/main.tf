##############################################################################################################
#
# FortiAnalyzer - a standalone FortiAnalyzer VM
# Terraform deployment template for AWS
#
##############################################################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-igw"
  })
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-rt"
  })
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-subnet"
  })
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# FortiAnalyzer Module
module "fortianalyzer" {
  source = "../../modules/single"

  prefix                = var.prefix
  name                  = "${var.prefix}-faz"
  region                = var.region
  availability_zone     = var.availability_zone
  vpc_id                = aws_vpc.main.id
  subnet_id             = aws_subnet.main.id
  username              = var.username
  password              = var.password
  key_name              = var.key_name
  faz_version           = var.faz_version
  faz_vmsize            = var.faz_vmsize
  faz_license_type      = var.faz_license_type
  admin_cidr            = var.admin_cidr
  faz_byol_license_file = var.faz_byol_license_file
  create_iam_role       = var.create_iam_role
}
