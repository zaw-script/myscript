#!/bin/bash

# ၁။ VPS ကို Update အရင်လုပ်မယ်
echo "System Update လုပ်နေပါပြီ..."
apt update -y

# ၂။ Web Panel အတွက် လိုအပ်တာတွေ အလိုအလျောက် သွင်းမယ်
echo "Apache နဲ့ PHP သွင်းနေပါပြီ..."
apt install apache2 php libapache2-mod-php php-mysql mysql-server -y

# ၃။ Database ဆောက်မယ်
echo "Database တည်ဆောက်နေပါပြီ..."
mysql -e "CREATE DATABASE IF NOT EXISTS zivpn;"
mysql -e "CREATE TABLE IF NOT EXISTS zivpn.users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50), exp_date DATE);"

echo "ကိုယ်ပိုင် Script အခြေခံ တည်ဆောက်မှု ပြီးစီးပါပြီဗျာ!"
