##############################################################################################################
#
# FortiAnalyzer - High Availability Deployment
# Terraform deployment template for AWS
#
##############################################################################################################

output "faz1_instance_id" {
  description = "Instance ID of FortiAnalyzer 1"
  value       = aws_instance.faz1.id
}

output "faz2_instance_id" {
  description = "Instance ID of FortiAnalyzer 2"
  value       = aws_instance.faz2.id
}

output "faz1_public_ip_address" {
  description = "Public IP address of FortiAnalyzer 1"
  value       = try(aws_eip.faz1[0].public_ip, null)
}

output "faz2_public_ip_address" {
  description = "Public IP address of FortiAnalyzer 2"
  value       = try(aws_eip.faz2[0].public_ip, null)
}

output "faz1_private_ip_address" {
  description = "Private IP address of FortiAnalyzer 1"
  value       = aws_instance.faz1.private_ip
}

output "faz2_private_ip_address" {
  description = "Private IP address of FortiAnalyzer 2"
  value       = aws_instance.faz2.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.fortianalyzer.id
}

output "deployment_summary" {
  description = "Deployment information summary"
  value = templatefile("${path.module}/templates/summary.tpl", {
    region                  = var.region
    faz1_public_ip_address  = try(aws_eip.faz1[0].public_ip, "N/A")
    faz2_public_ip_address  = try(aws_eip.faz2[0].public_ip, "N/A")
    faz1_private_ip_address = aws_instance.faz1.private_ip
    faz2_private_ip_address = aws_instance.faz2.private_ip
    faz1_instance_id        = aws_instance.faz1.id
    faz2_instance_id        = aws_instance.faz2.id
  })
}

# Network interface information
output "network_interface_id" {
  description = "ID of the management network interface"
  value       = aws_network_interface.faz1.id
}

# Volume information
output "log_volume_id" {
  description = "ID of the log storage volume"
  value       = var.enable_log_volume ? aws_ebs_volume.faz1_logs[0].id : null
}

# IAM information
output "iam_role_arn" {
  description = "ARN of the FortiAnalyzer IAM role"
  value       = var.create_iam_role ? aws_iam_role.fortianalyzer[0].arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_iam_role ? aws_iam_instance_profile.fortianalyzer[0].name : null
}

# AMI information
output "ami_id" {
  description = "AMI ID used for the FortiAnalyzer instance"
  value       = local.ami_id
}

output "ami_name" {
  description = "Name of the AMI used"
  value = var.faz_license_type == "byol" ? (
    length(data.aws_ami.fortianalyzer_byol) > 0 ? data.aws_ami.fortianalyzer_byol[0].name : null
    ) : (
    length(data.aws_ami.fortianalyzer_payg) > 0 ? data.aws_ami.fortianalyzer_payg[0].name : null
  )
}

# Deployment information
output "faz_license_type" {
  description = "License type used for deployment"
  value       = var.faz_license_type
}

output "fortianalyzer_version" {
  description = "FortiAnalyzer version deployed"
  value       = var.faz_version
}

output "faz1_availability_zone" {
  description = "Availability zone where FortiAnalyzer 1 is deployed"
  value       = aws_instance.faz1.availability_zone
}

output "faz2_availability_zone" {
  description = "Availability zone where FortiAnalyzer 2 is deployed"
  value       = aws_instance.faz2.availability_zone
}
