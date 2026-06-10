##############################################################################################################
#
# FortiAnalyzer - a standalone FortiAnalyzer VM
# Terraform deployment template for AWS
#
##############################################################################################################

# Basic configuration
variable "prefix" {
  description = "Prefix for all deployed resources"
  type        = string
}

variable "create_iam_role" {
  description = "Create IAM role for FortiAnalyzer"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "username" {
  description = "FortiAnalyzer admin username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "FortiAnalyzer admin password"
  type        = string
  sensitive   = true
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for deployment"
  type        = string
  default     = "us-west-2a"
}

# FortiAnalyzer configuration
variable "faz_vmsize" {
  description = "EC2 instance type for FortiAnalyzer"
  type        = string
  default     = "m5.large"
}

variable "faz_license_type" {
  description = "License type (byol or payg)"
  type        = string
  default     = "payg"

  validation {
    condition     = contains(["byol", "payg"], var.faz_license_type)
    error_message = "License type must be either 'byol' or 'payg'."
  }
}

variable "faz_version" {
  description = "FortiAnalyzer version"
  type        = string
  default     = "latest"
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "faz_byol_license_file" {
  description = "License file content for BYOL deployment"
  type        = string
  default     = ""
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

# Tags
variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiAnalyzer-Single"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}
