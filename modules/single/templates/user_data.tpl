Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
    set hostname "${faz_vm_name}"
    set management-port "${faz_admin_port}"
    set admin-lockout-duration 120
end
config system admin setting
    set gui-theme spring
    set idle_timeout 480
    set show-hostname enable
end
%{ if faz_ssh_public_key != "" }
config system admin user
    edit "${faz_username}"
        set ssh-public-key1 "${trimspace(file(faz_ssh_public_key))}"
    next
end
%{ endif }
%{ if faz_license_fortiflex != "" }
exec vm-license ${faz_license_fortiflex}
%{ endif }

%{ if faz_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${faz_license_file}"

${file(faz_license_file)}

%{ endif }
--===============0086047718136476635==--
