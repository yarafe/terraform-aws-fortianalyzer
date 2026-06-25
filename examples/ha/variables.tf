##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

# Basic configuration
variable "prefix" {
  description = "Prefix for all deployed resources"
  type        = string
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
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

  validation {
    condition     = var.ha_mode == "a-a" || var.ha_mode == "a-p"
    error_message = "The ha_ip variable must be either 'a-a' or 'a-p'."
  }
}

##############################################################################################################
# Deployment in AWS
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

##############################################################################################################
# Network Configuration
##############################################################################################################

variable "vpc" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    availability_zone = string
  }))
  description = ""

  default = [
    { name = "subnet-faz1", cidr = "172.16.136.0/26", availability_zone = "eu-north-1a" },  # FortiAnalyzer 1
    { name = "subnet-faz2", cidr = "172.16.136.64/26", availability_zone = "eu-north-1b" }  # FortiAnalyzer 2
  ]
}

##############################################################################################################
# FortiAnalyzer Specific Configuration
##############################################################################################################

variable "faz_vmsize" {
  description = "EC2 instance type for FortiAnalyzer"
  type        = string
  default     = "m5.xlarge"
}

variable "faz_version" {
  description = "FortiAnalyzer version"
  type        = string
  default     = "7.6.6"
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

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR blocks allowed for management access"
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

# FortiAnalyzer Additional Configuration
variable "create_iam_role" {
  description = "Create IAM role for FortiAnalyzer"
  type        = bool
  default     = true
}

# Reserved private IPs (optional)
variable "faz1_private_ip" {
  description = "Reserved private IP for FortiAnalyzer 1. Leave empty for dynamic assignment."
  type        = string
  default     = ""
}

variable "faz2_private_ip" {
  description = "Reserved private IP for FortiAnalyzer 2. Leave empty for dynamic assignment."
  type        = string
  default     = ""
}

variable "faz_ha_private_ip" {
  description = "Reserved private IP for the HA floating VIP (private HA mode only). Leave empty to auto-assign .100 host in the subnet."
  type        = string
  default     = ""
}

# Tags
variable "fortinet_tags" {
  description = "Fortinet specific tags"
  type        = map(string)
  default = {
    publisher = "Fortinet"
    template  = "FortiAnalyzer-HA"
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}
