##############################################################################################################
#
# FortiAnalyzer - a standalone FortiAnalyzer VM
# Terraform deployment template for AWS
#
##############################################################################################################

output "fortianalyzer_public_ip" {
  description = "Public IP address of the FortiAnalyzer instance"
  value       = module.fortianalyzer.public_ip_address
}

output "fortianalyzer_private_ip" {
  description = "Private IP address of the FortiAnalyzer instance"
  value       = module.fortianalyzer.private_ip_address
}

output "fortianalyzer_id" {
  description = "Instance ID of the FortiAnalyzer"
  value       = module.fortianalyzer.instance_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.fortianalyzer.security_group_id
}
