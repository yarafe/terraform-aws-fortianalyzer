##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################
# Variables
##############################################################################################################

variable "prefix" {
  description = "Prefix added to all deployed resources"
  type        = string
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "ha_ip" {
  description = "ha_ip: either 'public' or 'private'. Required only when ha_mode is 'a-p'."
  type        = string
  default     = "public"

  validation {
    condition     = var.ha_ip == null || var.ha_ip == "public" || var.ha_ip == "private"
    error_message = "The ha_ip variable must be either 'public' or 'private'."
  }
}

variable "ha_mode" {
  description = "ha_mode: either 'a-a' or 'a-p'"
  type        = string
  default     = "a-p"

  validation {
    condition     = var.ha_mode == "a-a" || var.ha_mode == "a-p"
    error_message = "The ha_ip variable must be either 'a-a' or 'a-p'."
  }
}

##############################################################################################################
# Network Configuration
##############################################################################################################

variable "vpc_id" {
  description = "VPC ID for FortiAnalyzer deployment"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of subnets to be connected to FortiAnalyzer VMs. Provide 1 subnet for a-p with private HA, 2 subnets for all other cases."
  validation {
    condition = (
      (var.ha_mode == "a-p" && var.ha_ip == "private" && length(var.subnet_ids) == 1) ||
      (!(var.ha_mode == "a-p" && var.ha_ip == "private") && length(var.subnet_ids) == 2)
    )
    error_message = "a-p with private HA requires 1 subnet ID; all other cases require exactly 2 subnet IDs."
  }
}

variable "subnet_availability_zones" {
  type        = list(string)
  description = "Availability zones of subnets to be connected to FortiAnalyzer VMs. Provide 1 AZ for a-p with private HA, 2 AZs for all other cases."
  validation {
    condition = (
      (var.ha_mode == "a-p" && var.ha_ip == "private" && length(var.subnet_availability_zones) == 1) ||
      (!(var.ha_mode == "a-p" && var.ha_ip == "private") && length(var.subnet_availability_zones) == 2)
    )
    error_message = "a-p with private HA requires 1 AZ; all other cases require exactly 2 AZs."
  }
}

##############################################################################################################
# FortiAnalyzer Specific Configuration
##############################################################################################################

variable "faz_version" {
  description = "FortiAnalyzer version for deployment"
  type        = string
  default     = "latest"
}

variable "faz_vmsize" {
  description = "EC2 instance type for FortiAnalyzer"
  type        = string
  default     = "m5.xlarge"
}

variable "faz_license_type" {
  description = "License type for FortiAnalyzer deployment (byol or payg)"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.faz_license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  default     = ""
}

variable "create_public_ip" {
  description = "Create and assign a public IP address"
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for FortiAnalyzer management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "fortigate_cidr" {
  description = "CIDR blocks for FortiGate log sources"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# FortiAnalyzer HA Configuration
variable "ha_password" {
  description = "Password for FortiAnalyzer HA"
  type        = string
  sensitive   = true
}

variable "ha_group_id" {
  description = "HA group ID for FortiAnalyzer HA cluster"
  type        = number
  default     = 1
}

variable "ha_group_name" {
  description = "HA group name for FortiAnalyzer HA cluster"
  type        = string
  default     = "FAZHA"
}

variable "faz1_byol_serial_number" {
  description = "Serial number of FortiAnalyzer unit 1 for HA peer configuration"
  type        = string
  default     = ""
}

variable "faz2_byol_serial_number" {
  description = "Serial number of FortiAnalyzer unit 2 for HA peer configuration"
  type        = string
  default     = ""
}

# FortiAnalyzer license configuration
variable "faz1_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "faz1_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

variable "faz2_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
}

variable "faz2_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

##############################################################################################################
# Storage Configuration
##############################################################################################################

variable "faz_root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "faz_log_volume_size" {
  description = "Size of the log volume in GB"
  type        = number
  default     = 100
}

variable "faz_log_volume_type" {
  description = "Type of the log volume"
  type        = string
  default     = "gp3"
}

variable "enable_log_volume" {
  description = "Enable additional volume for log storage"
  type        = bool
  default     = true
}

##############################################################################################################
# Additional Configuration
##############################################################################################################

variable "faz_admin_port" {
  description = "Admin port for FortiAnalyzer management interface"
  type        = number
  default     = 443
}

variable "create_iam_role" {
  description = "Create IAM role for FortiAnalyzer"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable EC2 termination protection"
  type        = bool
  default     = false
}

variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiAnalyzer-HA"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}
