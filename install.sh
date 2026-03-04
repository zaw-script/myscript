#!/bin/bash

# ၁။ လိုအပ်တာတွေ သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget -y

# ၂။ IP Address ယူမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ User နဲ့ Pass တောင်းမယ်
echo "--- VPN Panel Admin Setup ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ ရိုက်ထည့်လိုက်တာကို /var/www/html/config.php ထဲမှာ သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "Admin Web Panel Link: http://$MYIP"
echo "Username: $adm_user"
echo "Password: $adm_pass"
echo "------------------------------------------"
