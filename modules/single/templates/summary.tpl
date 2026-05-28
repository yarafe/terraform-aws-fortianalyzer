-------------------------------------------------
FortiAnalyzer Deployment Summary
-------------------------------------------------

Region: ${region}
Username: ${faz_username}
Public IP: ${public_ip_address}
Private IP: ${private_ip_address}

To access FortiAnalyzer:
GUI: https://${public_ip_address}
SSH: ssh -i <key-pair>.pem admin@${public_ip_address}

IMPORTANT:
- Change the admin password after initial login
- Configure your firewall rules appropriately
- Keep your license and software up to date
