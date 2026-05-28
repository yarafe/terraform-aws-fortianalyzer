# FortiAnalyzer High Availability Module

This module deploys a High Availability pair of FortiAnalyzer instances on AWS using active-active HA mode.

## Features

- Deploys two FortiAnalyzer instances in active-active HA mode
- Support for BYOL (FortiFlex token or license file) and PAYG licensing
- Configurable HA group ID and group name
- Optional public IP addresses per instance
- Encrypted EBS volumes for root and log storage

## Usage

### Example

```hcl
module "fortianalyzer" {
  source = "../../modules/ha"

  prefix                            = var.prefix
  region                            = var.region
  vpc_id                            = aws_vpc.main.id
  subnet_ids                        = [aws_subnet.faz1.id, aws_subnet.faz2.id]
  subnet_availability_zones         = ["eu-north-1a", "eu-north-1b"]
  key_name                          = var.key_name
  faz_version                       = var.faz_version
  faz_license_type                  = var.faz_license_type
  admin_cidr                        = var.admin_cidr
  ha_ip                             = "public"
  ha_password                       = var.ha_password
  ha_group_id                       = 1
  ha_group_name                     = "FAZHA"
  faz1_byol_fortiflex_license_token = var.faz1_byol_fortiflex_license_token
  faz2_byol_fortiflex_license_token = var.faz2_byol_fortiflex_license_token
  faz1_byol_serial_number           = var.faz1_byol_serial_number
  faz2_byol_serial_number           = var.faz2_byol_serial_number
}
```

## Input Variables

| Name                             | Description                                     | Type         | Default        | Required |
|----------------------------------|-------------------------------------------------|--------------|----------------|:--------:|
| prefix                           | Prefix added to all deployed resources          | string       | n/a            | yes      |
| region                           | AWS region                                      | string       | n/a            | yes      |
| vpc_id                           | VPC ID for FortiAnalyzer deployment            | string       | n/a            | yes      |
| subnet_ids                       | List of 2 subnet IDs (faz1, faz2)              | list(string) | n/a            | yes      |
| subnet_availability_zones        | List of 2 AZs for the subnets                  | list(string) | n/a            | yes      |
| ha_ip                            | EIP mode: 'public' or 'private'                | string       | n/a            | yes      |
| ha_password                      | HA cluster password                             | string       | n/a            | yes      |
| ha_group_id                      | HA group ID                                     | number       | 1              | no       |
| ha_group_name                    | HA group name                                   | string       | "FAZHA"        | no       |
| faz_version                      | FortiAnalyzer version                          | string       | "latest"       | no       |
| faz_license_type                 | License type (byol or payg)                    | string       | "payg"         | no       |
| faz1_byol_serial_number          | Serial number of FAZ unit 1                    | string       | ""             | no       |
| faz2_byol_serial_number          | Serial number of FAZ unit 2                    | string       | ""             | no       |
| faz1_byol_fortiflex_license_token| FortiFlex token for FAZ unit 1                 | string       | ""             | no       |
| faz2_byol_fortiflex_license_token| FortiFlex token for FAZ unit 2                 | string       | ""             | no       |
| faz1_byol_license_file           | License file for FAZ unit 1                    | string       | ""             | no       |
| faz2_byol_license_file           | License file for FAZ unit 2                    | string       | ""             | no       |

## Outputs

| Name                    | Description                                  |
|-------------------------|----------------------------------------------|
| faz1_instance_id        | Instance ID of FortiAnalyzer 1              |
| faz2_instance_id        | Instance ID of FortiAnalyzer 2              |
| faz1_public_ip_address  | Public IP address of FortiAnalyzer 1        |
| faz2_public_ip_address  | Public IP address of FortiAnalyzer 2        |
| faz1_private_ip_address | Private IP address of FortiAnalyzer 1       |
| faz2_private_ip_address | Private IP address of FortiAnalyzer 2       |
| security_group_id       | ID of the security group                     |
| deployment_summary      | Deployment information summary               |

---

For more advanced usage, see the `examples/ha` directory.
