##############################################################################################################
#
# FortiAnalyzer - a standalone FortiAnalyzer VM
# Terraform deployment template for AWS
#
##############################################################################################################
# Variables
##############################################################################################################

variable "prefix" {
  description = "Prefix added to all deployed resources"
  type        = string
}

variable "availability_zone" {
  description = "AWS region availability zone for deployment"
  type        = string
}

variable "username" {
  description = "Username for FortiAnalyzer admin"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Password for FortiAnalyzer admin"
  type        = string
  sensitive   = true
}

##############################################################################################################
# Network Configuration
##############################################################################################################

variable "subnet_id" {
  description = "Subnet ID for FortiAnalyzer deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for FortiAnalyzer deployment"
  type        = string
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
  default     = "m5.large"
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

variable "faz_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "faz_byol_fortiflex_license_token" {
  description = "FortiFlex license token content for BYOL deployment"
  type        = string
  default     = ""
}

variable "faz_ssh_public_key_file" {
  description = "SSH public key file for FortiAnalyzer access"
  type        = string
  default     = ""
}

variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiAnalyzer-Single"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
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

variable "private_ip" {
  description = "Private IP address to assign to the FortiAnalyzer instance"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "name" {
  description = "Name for the FortiAnalyzer deployment"
  type        = string
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
