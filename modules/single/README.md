# FortiAnalyzer Single Instance Module

This module deploys a single FortiAnalyzer instance on AWS. It is designed to be used with external VPC and subnet resources, which should be created in your example or root configuration.

## Features

- Deploys a single FortiAnalyzer instance (BYOL or PAYG)
- Minimal required variables: prefix, region, username, password, vpc_id, subnet_id, key_name
- All network infrastructure (VPC, subnet, routing) is handled outside the module
- Only FortiAnalyzer-specific resources are managed in the module

## Usage

### Example

```hcl
# In your root or example configuration:

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # ...other VPC settings...
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  # ...other subnet settings...
}

module "fortianalyzer" {
  source           = "../../modules/single"
  prefix           = var.prefix
  region           = var.region
  vpc_id           = aws_vpc.main.id
  subnet_id        = aws_subnet.main.id
  username         = var.username
  password         = var.password
  key_name         = var.key_name
  faz_version      = var.faz_version
  faz_license_type = var.faz_license_type
  admin_cidr       = var.admin_cidr
  fortigate_cidr   = var.fortigate_cidr
  faz_byol_license_file = var.faz_byol_license_file
}
```

## Input Variables

| Name           | Description                                      | Type          | Default         | Required |
|----------------|--------------------------------------------------|---------------|-----------------|:--------:|
| prefix         | Prefix added to all deployed resources           | string        | n/a             | yes      |
| region         | AWS region                                       | string        | n/a             | yes      |
| vpc_id         | VPC ID for FortiAnalyzer deployment             | string        | n/a             | yes      |
| subnet_id      | Subnet ID for FortiAnalyzer deployment          | string        | n/a             | yes      |
| username       | Username for FortiAnalyzer admin                | string        | "admin"         | no       |
| password       | Password for FortiAnalyzer admin                | string        | n/a             | yes      |
| key_name       | AWS key pair name for SSH access                 | string        | n/a             | yes      |
| faz_version    | FortiAnalyzer version for deployment            | string        | "latest"        | no       |
| faz_license_type | License type (byol or payg)                    | string        | "payg"          | no       |
| create_public_ip | Create and assign a public IP address           | bool          | true            | no       |
| admin_cidr     | CIDR blocks allowed for management access        | list(string)  | ["0.0.0.0/0"]   | no       |
| fortigate_cidr | CIDR blocks for FortiGate log sources            | list(string)  | ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] | no |
| faz_byol_license_file | License file for BYOL deployment          | string        | ""              | no       |
| faz_byol_fortiflex_license_token | FortiFlex token for BYOL deployment | string   | ""              | no       |
| fortinet_tags  | Fortinet specific tags                           | map(string)   | see variables.tf| no       |
| faz_root_volume_size | Size of the root volume in GB               | number        | 100             | no       |
| faz_log_volume_size  | Size of the log volume in GB                | number        | 100             | no       |
| enable_log_volume| Enable additional volume for log storage        | bool          | true            | no       |

## Outputs

| Name                  | Description                                 |
|-----------------------|---------------------------------------------|
| instance_id           | Instance ID of the FortiAnalyzer           |
| private_ip_address    | Private IP address of the FortiAnalyzer     |
| public_ip_address     | Public IP address of the FortiAnalyzer      |
| security_group_id     | ID of the security group                     |
| deployment_summary    | Deployment information summary               |
| network_interface_id  | ID of the management network interface       |
| log_volume_id         | ID of the log storage volume                 |

## Notes

- All VPC, subnet, and routing resources should be created outside the module (in your example or root configuration).
- Only pass IDs and FortiAnalyzer-specific settings to the module.

---

For more advanced usage, see the `examples/single` directory.
