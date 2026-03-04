#!/bin/bash

# ၁။ လိုအပ်တာတွေ သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php php-mysql mysql-server wget -y

# ၂။ MySQL ကို အရင်ဖွင့်မယ် (ဒါမှ Error မတက်မှာပါ)
service mysql start

# ၃။ Database ဆောက်မယ်
mysql -e "CREATE DATABASE IF NOT EXISTS zivpn;"
mysql -e "CREATE TABLE IF NOT EXISTS zivpn.users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50));"

# ၄။ IP Address ယူမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၅။ Script Run တဲ့အချိန်မှာ User နဲ့ Pass တောင်းမယ်
echo "--- VPN Panel Admin Setup ---"
read -p "Admin အသစ်အတွက် Username ရိုက်ထည့်ပါ: " adm_user
read -p "Admin အသစ်အတွက် Password ရိုက်ထည့်ပါ: " adm_pass

# ၆။ ရိုက်ထည့်လိုက်တဲ့ User/Pass ကို Database ထဲ သိမ်းမယ်
mysql -e "INSERT INTO zivpn.users (username, password) VALUES ('$adm_user', '$adm_pass');"

echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "Admin Web Panel Link: http://$MYIP"
echo "Username: $adm_user"
echo "Password: $adm_pass"
echo "------------------------------------------"
