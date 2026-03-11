#!/bin/bash

echo "=========================================="
echo "      ZIVPN Panel Setup အဆင့်ဆင့်           "
echo "=========================================="

# ၁။ Admin Username မေးမယ်
read -p "၁။ Admin Username ဘာပေးမလဲ? : " admin_user

# ၂။ Admin Password မေးမယ်
read -p "၂။ Admin Password ဘာပေးမလဲ? : " admin_pass

# ၃။ Admin Telegram Link မေးမယ်
read -p "၃။ Admin ဆက်သွယ်ရမည့် Telegram Link? : " admin_link

echo "------------------------------------------"
echo "စနစ်အား တင်သွင်းနေပါသည်... ကျေးဇူးပြု၍ ခဏစောင့်ပေးပါ။"
echo "------------------------------------------"

# စနစ်ပြင်ဆင်ခြင်း
apt update -y && apt install python3-pip -y
pip3 install flask

mkdir -p /etc/zivpn
wget -O /etc/zivpn/web.py https://raw.githubusercontent.com/zaw-script/myscript/main/web.py

# Bro ရိုက်ထည့်လိုက်တဲ့ အချက်အလက်တွေကို Code ထဲ အစားထိုးခြင်း
sed -i "s|ADMIN_USER = .*|ADMIN_USER = \"$admin_user\"|" /etc/zivpn/web.py
sed -i "s|ADMIN_PASS = .*|ADMIN_PASS = \"$admin_pass\"|" /etc/zivpn/web.py
sed -i "s|ADMIN_CONTACT = .*|ADMIN_CONTACT = \"$admin_link\"|" /etc/zivpn/web.py

# Panel ကို ပြန်စတင်ခြင်း
fuser -k 8080/tcp
nohup python3 /etc/zivpn/web.py > /dev/null 2>&1 &

echo "=========================================="
echo "Panel တင်သွင်းမှု ပြီးဆုံးပါပြီ!"
echo "Login Link: http://$(hostname -I | awk '{print $1}'):8080"
echo "Username: $admin_user"
echo "Password: $admin_pass"
echo "=========================================="
