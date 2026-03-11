#!/bin/bash
apt update -y
apt install python3-pip -y
pip3 install flask
mkdir -p /etc/zivpn
wget -O /etc/zivpn/web.py https://raw.githubusercontent.com/zaw-script/myscript/main/web.py
python3 /etc/zivpn/web.py &
echo "Panel installed successfully"
