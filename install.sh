#!/bin/bash
# ZIVPN UDP Web UI - Fixed Version (Original UI + Full Edit)
set -euo pipefail

# Path setup
mkdir -p /etc/zivpn/templates

# --- Web Login & Admin Config ---
ENVF="/etc/zivpn/web.env"
if [ ! -f "$ENVF" ]; then
    echo -e "🔒 Web Admin အတွက် အချက်အလက်သစ်များ သတ်မှတ်ပေးပါ"
    read -r -p "Admin Username: " WEB_USER
    read -r -s -p "Admin Password: " WEB_PASS; echo
    read -r -p "Contact Link (ဥပမာ: https://t.me/yourname): " CONTACT_LINK
    
    WEB_SECRET="$(openssl rand -hex 32)"
    echo "WEB_ADMIN_USER=${WEB_USER}" > "$ENVF"
    echo "WEB_ADMIN_PASSWORD=${WEB_PASS}" >> "$ENVF"
    echo "WEB_SECRET=${WEB_SECRET}" >> "$ENVF"
    echo "WEB_CONTACT_LINK=${CONTACT_LINK}" >> "$ENVF"
fi

# --- Python Web Script (Login & Edit Function ပါဝင်ပြီး) ---
cat >/etc/zivpn/web.py <<'PY'
import os, json, subprocess
from flask import Flask, render_template, request, redirect, url_for, session
from datetime import datetime, timedelta, date

app = Flask(__name__)
app.secret_key = os.environ.get("WEB_SECRET")

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD")
CONTACT_LINK = os.environ.get("WEB_CONTACT_LINK")

def load_users():
    try:
        with open(USERS_FILE, "r") as f: return json.load(f)
    except: return []

def save_and_sync(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)
    # Sync to ZIVPN Config
    today = date.today()
    valid = [u['password'] for u in users if not u.get('expires') or datetime.strptime(u['expires'], "%Y-%m-%d").date() >= today]
    try:
        with open(CONFIG_FILE, "r") as f: cfg = json.load(f)
        cfg['auth']['config'] = valid
        with open(CONFIG_FILE, "w") as f: json.dump(cfg, f, indent=2)
        subprocess.run(["systemctl", "restart", "zivpn"], check=False)
    except: pass

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect(url_for("index"))
    # Login Page မှာ link ပါဝင်စေရန်
    return f'''
    <html><body style="text-align:center; padding-top:50px; font-family:sans-serif;">
    <h2>Login to Admin Panel</h2>
    <form method="post">
        <input name="u" placeholder="Username" required><br><br>
        <input name="p" type="password" placeholder="Password" required><br><br>
        <button type="submit">Login</button>
    </form>
    <br><a href="{CONTACT_LINK}" target="_blank">Contact Admin</a>
    </body></html>
    '''

@app.route("/")
def index():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    # ရှင်းရှင်းလင်းလင်း User List ပြသရန်
    rows = "".join([f"<tr><td>{u['user']}</td><td>{u['password']}</td><td>{u['expires']}</td><td><a href='/edit/{u['user']}'>[ပြင်ရန်]</a></td></tr>" for u in users])
    return f"<h2>User Management</h2><table border='1'>{rows}</table><br><a href='/add'>User အသစ်ထည့်ရန်</a>"

@app.route("/edit/<username>", methods=["GET", "POST"])
def edit(username):
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    user = next((u for u in users if u["user"] == username), None)
    if request.method == "POST":
        user["password"] = request.form.get("pass")
        exp = request.form.get("exp")
        if exp.isdigit():
            user["expires"] = (date.today() + timedelta(days=int(exp))).strftime("%Y-%m-%d")
        else:
            user["expires"] = exp
        save_and_sync(users)
        return redirect(url_for("index"))
    return f"<h2>Edit {username}</h2><form method='post'>Password: <input name='pass' value='{user['password']}'><br>Days or Date: <input name='exp' value='{user['expires']}'><br><button type='submit'>Update</button></form>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

# Restart Services
systemctl restart zivpn-web 2>/dev/null || (cat <<EOF >/etc/systemd/system/zivpn-web.service
[Unit]
Description=ZIVPN Web UI
[Service]
EnvironmentFile=$ENVF
ExecStart=/usr/bin/python3 /etc/zivpn/web.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now zivpn-web)

echo "✅ Web UI ကို ပြန်ပြင်ပြီးပါပြီ။ http://$(hostname -I | awk '{print $1}'):8080 ကို ဝင်ကြည့်ပါ။"
