-------------------------------------------------
FortiAnalyzer HA Deployment Summary
-------------------------------------------------

Region: ${region}
Username: admin

FortiAnalyzer 1
Instance id: ${faz1_instance_id}
Public IP: ${faz1_public_ip_address}
Private IP: ${faz1_private_ip_address}

FortiAnalyzer 2
Instance id: ${faz2_instance_id}
Public IP: ${faz2_public_ip_address}
Private IP: ${faz2_private_ip_address}

To access FortiAnalyzer:
GUI: https://${faz1_public_ip_address}
GUI: https://${faz2_public_ip_address}

SSH: ssh -i <key-pair>.pem admin@${faz1_public_ip_address}
SSH: ssh -i <key-pair>.pem admin@${faz2_public_ip_address}

IMPORTANT:
- Change the admin password after initial login
- Configure your firewall rules appropriately
- Keep your license and software up to date
