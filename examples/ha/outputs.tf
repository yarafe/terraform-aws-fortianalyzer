##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

output "faz1_public_ip" {
  description = "Public IP address of FortiAnalyzer 1"
  value       = module.fortianalyzer.faz1_public_ip_address
}

output "faz1_private_ip_address" {
  description = "Private IP address of FortiAnalyzer 1"
  value       = module.fortianalyzer.faz1_private_ip_address
}

output "faz2_public_ip" {
  description = "Public IP address of FortiAnalyzer 2"
  value       = module.fortianalyzer.faz2_public_ip_address
}

output "faz2_private_ip_address" {
  description = "Private IP address of FortiAnalyzer 2"
  value       = module.fortianalyzer.faz2_private_ip_address
}

output "faz1_instance_id" {
  description = "Instance ID of FortiAnalyzer 1"
  value       = module.fortianalyzer.faz1_instance_id
}

output "faz2_instance_id" {
  description = "Instance ID of FortiAnalyzer 2"
  value       = module.fortianalyzer.faz2_instance_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.fortianalyzer.security_group_id
}

output "deployment_summary" {
  description = "Deployment information summary"
  value       = module.fortianalyzer.deployment_summary
}
