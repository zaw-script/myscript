#!/bin/bash
apt update -y
apt install python3-pip -y
pip3 install flask
mkdir -p /etc/zivpn
wget -O /etc/zivpn/web.py https://raw.githubusercontent.com/zaw-script/myscript/main/web.py
# အောက်က စာကြောင်းမှာ & လေး ပါတာ သေချာပါစေ (ဒါမှ အနောက်မှာ Run မှာပါ)
python3 /etc/zivpn/web.py > /dev/null 2>&1 &
echo "------------------------------------------"
echo "ZIVPN Panel Installed Successfully!"
echo "Access it at: http://$(hostname -I | awk '{print $1}'):8080"
echo "------------------------------------------"
