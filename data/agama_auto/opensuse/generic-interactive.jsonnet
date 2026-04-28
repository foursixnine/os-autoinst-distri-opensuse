{
   "bootloader": {
      "stopOnBootMenu": true
   },
   "root": {
    "password": "$6$vYbbuJ9WMriFxGHY$gQ7shLw9ZBsRcPgo6/8KmfDvQ/lCqxW8/WnMoLCoWGdHO6Touush1nhegYfdBbXRpsQuy/FTZZeg7gQL50IbA/",
    "hashedPassword": true,
      "sshPublicKey": "fake public key to enable sshd and open firewall"
   },
   "scripts": {
      "post": [
         {
            "chroot": true,
            "content": "#!/usr/bin/env bash\necho 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/root.conf\n",
            "name": "enable root login"
         }
      ]
   }
}
