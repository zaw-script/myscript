#!/bin/bash
# ZIVPN Original Orange UI + Full Edit Feature
set -euo pipefail

# အရင် folder အဟောင်းတွေကို ရှင်းထုတ်ပြီး အသစ်ပြန်ဆောက်မယ်
rm -rf /etc/zivpn/templates
mkdir -p /etc/zivpn/templates

# Admin Login သတ်မှတ်ချက်
ENVF="/etc/zivpn/web.env"
echo "WEB_ADMIN_USER=admin" > "$ENVF"
echo "WEB_ADMIN_PASSWORD=admin" >> "$ENVF"
echo "WEB_SECRET=$(openssl rand -hex 32)" >> "$ENVF"
echo "WEB_CONTACT_LINK=https://t.me/yourid" >> "$ENVF"

# --- Python Web Script (Bro ရဲ့ မူရင်း UI design ကို အခြေခံထားသည်) ---
cat >/etc/zivpn/web.py <<'PY'
import os, json, subprocess
from flask import Flask, render_template_string, request, redirect, url_for, session
from datetime import datetime, timedelta, date

app = Flask(__name__)
app.secret_key = os.environ.get("WEB_SECRET")

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER", "admin")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD", "admin")

def load_users():
    try:
        with open(USERS_FILE, "r") as f: return json.load(f)
    except: return []

def save_and_sync(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)
    today = date.today()
    valid = [u['password'] for u in users if not u.get('expires') or datetime.strptime(u['expires'], "%Y-%m-%d").date() >= today]
    try:
        with open(CONFIG_FILE, "r") as f: cfg = json.load(f)
        cfg['auth']['config'] = valid
        with open(CONFIG_FILE, "w") as f: json.dump(cfg, f, indent=2)
        subprocess.run(["systemctl", "restart", "zivpn"], check=False)
    except: pass

# မူရင်း Orange Design Style
STYLE = '''
<style>
    body { font-family: sans-serif; background: #f0f2f5; margin: 0; display: flex; align-items: center; justify-content: center; height: 100vh; }
    .card { background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); width: 350px; text-align: center; }
    .logo-circle { background: #ff851b; width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 15px; border: 4px solid #ff851b; outline: 2px solid white; }
    .logo-circle span { color: white; font-size: 24px; font-weight: bold; }
    input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; }
    .btn { background: #ff851b; color: white; border: none; padding: 12px; width: 100%; border-radius: 8px; font-size: 16px; cursor: pointer; margin-top: 10px; }
    .contact { display: block; margin-top: 15px; color: #ff851b; text-decoration: none; font-size: 14px; }
</style>
'''

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect(url_for("dashboard"))
    return render_template_string(STYLE + '''
    <div class="card">
        <div class="logo-circle"><span>ZIV</span></div>
        <h2 style="color:#333;">ZIVPN Panel</h2>
        <p style="color:#ff851b; font-weight:bold;">Server IP: {{ip}}</p>
        <form method="post">
            <input name="u" placeholder="Username" required>
            <input name="p" type="password" placeholder="Password" required>
            <button class="btn" type="submit">Login</button>
        </form>
        <a href="#" class="contact">💬 Admin ကို ဆက်သွယ်ပါ</a>
    </div>
    ''', ip=request.host.split(':')[0])

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    return render_template_string(STYLE + '''
    <div class="card" style="width: 450px;">
        <h3>Member User စုစုပေါင်း: {{ count }} ယောက်</h3>
        <form action="/add" method="post">
            <input name="u" placeholder="Username" required>
            <input name="p" placeholder="Password" required>
            <input name="e" placeholder="ရက်ပေါင်း (ဥပမာ: 30)" required>
            <button class="btn" type="submit">Create Account</button>
        </form>
        <hr>
        <table style="width:100%; margin-top:15px; font-size:14px;">
            <tr><th>User</th><th>Pass</th><th>Exp</th><th>Action</th></tr>
            {% for u in users %}
            <tr>
                <td>{{ u.user }}</td>
                <td>{{ u.password }}</td>
                <td>{{ u.expires }}</td>
                <td><a href="/edit/{{ u.user }}" style="color:#ff851b;">[ပြင်ရန်]</a></td>
            </tr>
            {% endfor %}
        </table>
    </div>
    ''', count=len(users), users=users)

@app.route("/edit/<username>", methods=["GET", "POST"])
def edit_user(username):
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    user = next((u for u in users if u["user"] == username), None)
    if request.method == "POST":
        user["password"] = request.form.get("p")
        exp = request.form.get("e")
        if exp.isdigit():
            user["expires"] = (date.today() + timedelta(days=int(exp))).strftime("%Y-%m-%d")
        else:
            user["expires"] = exp
        save_and_sync(users)
        return redirect(url_for("dashboard"))
    return render_template_string(STYLE + f'''
    <div class="card">
        <h3>ပြင်ဆင်ရန်: {username}</h3>
        <form method="post">
            <input name="p" value="{user['password']}" placeholder="Password">
            <input name="e" value="{user['expires']}" placeholder="ရက်ပေါင်း (သို့) 2025-12-31">
            <button class="btn" type="submit">Update Account</button>
        </form>
    </div>
    ''')

@app.route("/add", methods=["POST"])
def add_user():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    u, p, e = request.form.get("u"), request.form.get("p"), request.form.get("e")
    if e.isdigit():
        exp = (date.today() + timedelta(days=int(e))).strftime("%Y-%m-%d")
    else:
        exp = e
    users.append({"user": u, "password": p, "expires": exp})
    save_and_sync(users)
    return redirect(url_for("dashboard"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

# Service restart လုပ်မယ်
systemctl stop zivpn-web || true
cat <<EOF >/etc/systemd/system/zivpn-web.service
[Unit]
Description=ZIVPN Web Service
[Service]
EnvironmentFile=$ENVF
ExecStart=/usr/bin/python3 /etc/zivpn/web.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now zivpn-web
