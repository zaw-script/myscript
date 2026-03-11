#!/bin/bash

# Admin User နဲ့ Pass ကို လှမ်းမေးမယ်
echo "------------------------------------------"
read -p "Enter Admin Username: " admin_user
read -p "Enter Admin Password: " admin_pass
echo "------------------------------------------"

apt update -y
apt install python3-pip -y
pip3 install flask

mkdir -p /etc/zivpn

# web.py ကို အရင်ဆွဲမယ်
wget -O /etc/zivpn/web.py https://raw.githubusercontent.com/zaw-script/myscript/main/web.py

# အပေါ်က ရိုက်ခဲ့တဲ့ User/Pass ကို web.py ထဲမှာ အစားထိုးမယ်
sed -i "s/ADMIN_USER = .*/ADMIN_USER = \"$admin_user\"/" /etc/zivpn/web.py
sed -i "s/ADMIN_PASS = .*/ADMIN_PASS = \"$admin_pass\"/" /etc/zivpn/web.py

# Panel ကို Run မယ်
fuser -k 8080/tcp
nohup python3 /etc/zivpn/web.py > /dev/null 2>&1 &

echo "-------------------------------------------"
echo "ZIVPN Panel Installed Successfully!"
echo "Login URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "Admin User: $admin_user"
echo "Admin Pass: $admin_pass"
echo "-------------------------------------------"
