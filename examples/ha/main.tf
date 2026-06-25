##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

##############################################################################################################
# Networking
##############################################################################################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-igw"
  })
}

resource "aws_subnet" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-${each.key}"
  })
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.fortinet_tags, {
    Name = "${var.prefix}-rt"
  })
}

resource "aws_route_table_association" "rt_subnet1" {
  for_each = aws_subnet.subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# FortiAnalyzer Module
module "fortianalyzer" {
  source = "../../modules/ha"

  prefix                            = var.prefix
  region                            = var.region
  vpc_id                            = aws_vpc.vpc.id
  subnet_ids                        = (var.ha_mode == "a-p" && var.ha_ip == "private") ? [aws_subnet.subnets[var.subnets[0].name].id] : [aws_subnet.subnets[var.subnets[0].name].id, aws_subnet.subnets[var.subnets[1].name].id]
  subnet_availability_zones         = (var.ha_mode == "a-p" && var.ha_ip == "private") ? [aws_subnet.subnets[var.subnets[0].name].availability_zone] : [aws_subnet.subnets[var.subnets[0].name].availability_zone, aws_subnet.subnets[var.subnets[1].name].availability_zone]
  faz_version                       = var.faz_version
  faz_vmsize                        = var.faz_vmsize
  faz_license_type                  = var.faz_license_type
  admin_cidr                        = var.admin_cidr
  fortigate_cidr                    = var.fortigate_cidr
  faz1_byol_license_file            = var.faz1_byol_license_file
  faz1_byol_fortiflex_license_token = var.faz1_byol_fortiflex_license_token
  faz2_byol_license_file            = var.faz2_byol_license_file
  faz2_byol_fortiflex_license_token = var.faz2_byol_fortiflex_license_token
  faz1_byol_serial_number           = var.faz1_byol_serial_number
  faz2_byol_serial_number           = var.faz2_byol_serial_number
  ha_ip                             = var.ha_ip
  ha_mode                           = var.ha_mode
  ha_password                       = var.ha_password
  ha_group_id                       = var.ha_group_id
  ha_group_name                     = var.ha_group_name
  create_iam_role                   = var.create_iam_role
  faz1_private_ip                   = var.faz1_private_ip
  faz2_private_ip                   = var.faz2_private_ip
  faz_ha_private_ip                 = var.faz_ha_private_ip
}
