#!/bin/bash
# ZIVPN Panel Installation
apt update -y && apt install python3-pip -y
pip3 install flask
wget -O /etc/zivpn/web.py https://raw.githubusercontent.com/zaw-script/myscript/main/web.py
# panel ကို စတင်ခြင်း
python3 /etc/zivpn/web.py &
echo "Panel installed successfully"
