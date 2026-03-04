#!/bin/bash
apt update -y
apt install apache2 php libapache2-mod-php wget -y
MYIP=$(wget -qO- ipv4.icanhazip.com)
echo "--- VPN Panel Admin Setup ---"
echo -n "Admin Username ပေးပါ: "
read adm_user
echo -n "Admin Password ပေးပါ: "
read adm_pass
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php
echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "Admin Web Panel Link: http://$MYIP"
echo "------------------------------------------"
