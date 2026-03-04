#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget -y

# ၂။ IP Address ကို ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ User နဲ့ Pass ကို တစ်ဆင့်ချင်း မေးမယ်
echo "--- VPN Panel Admin Setup ---"
echo -n "Admin Username ပေးပါ: "
read adm_user
echo -n "Admin Password ပေးပါ: "
read adm_pass

# ၄။ ရိုက်ထည့်လိုက်တဲ့ အချက်အလက်ကို သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "Admin Web Panel Link: http://$MYIP"
echo "Username: $adm_user"
echo "Password: $adm_pass"
echo "------------------------------------------"
