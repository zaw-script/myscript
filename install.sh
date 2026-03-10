#!/bin/bash
# ZIVPN Ultimate Panel: All-in-One Pro UI
set -euo pipefail

# 1. Environment & Setup
ENVF="/etc/zivpn/web.env"
if [ ! -f "$ENVF" ]; then
    echo -e "\e[1;33m🔒 Web Admin Login သတ်မှတ်ပေးပါ\e[0m"
    read -r -p "Admin Username: " WEB_USER
    read -r -s -p "Admin Password: " WEB_PASS; echo
    read -r -p "Contact Link (ဥပမာ Telegram): " CONTACT_LINK
    echo "WEB_ADMIN_USER=${WEB_USER}" > "$ENVF"
    echo "WEB_ADMIN_PASSWORD=${WEB_PASS}" >> "$ENVF"
    echo "WEB_SECRET=$(openssl rand -hex 32)" >> "$ENVF"
    echo "WEB_CONTACT_LINK=${CONTACT_LINK}" >> "$ENVF"
fi

# 2. Python Web Script (Professional Features)
cat >/etc/zivpn/web.py <<'PY'
import os, json, subprocess, socket
from flask import Flask, render_template_string, request, redirect, url_for, session
from datetime import datetime, timedelta, date

app = Flask(__name__)
app.secret_key = os.environ.get("WEB_SECRET")

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD")
CONTACT_LINK = os.environ.get("WEB_CONTACT_LINK", "#")

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except: return "127.0.0.1"

def load_users():
    try:
        if os.path.exists(USERS_FILE):
            with open(USERS_FILE, "r") as f: return json.load(f)
    except: pass
    return []

def save_and_sync(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)
    today = date.today()
    valid = [u['password'] for u in users if not u.get('expires') or datetime.strptime(u['expires'], "%Y-%m-%d").date() >= today]
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "r") as f: cfg = json.load(f)
            cfg['auth']['config'] = valid
            with open(CONFIG_FILE, "w") as f: json.dump(cfg, f, indent=2)
            subprocess.run(["systemctl", "restart", "zivpn"], check=False)
    except: pass

STYLE = '''
<style>
    :root { --main: #ff851b; --bg: #f8f9fa; }
    body { font-family: 'Segoe UI', sans-serif; background: var(--bg); margin: 0; padding: 15px; }
    .card { background: white; padding: 20px; border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); max-width: 500px; margin: auto; }
    .logo { background: var(--main); color: white; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 10px; font-weight: bold; font-size: 20px; }
    input { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; }
    .btn { background: var(--main); color: white; border: none; padding: 12px; width: 100%; border-radius: 8px; font-weight: bold; cursor: pointer; transition: 0.3s; }
    .btn:hover { opacity: 0.8; }
    .btn-del { background: #ff4136; padding: 5px 10px; font-size: 12px; border-radius: 5px; color: white; text-decoration: none; }
    .status-on { color: #2ecc40; font-weight: bold; }
    .status-off { color: #ff4136; font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13px; }
    th, td { padding: 12px 8px; border-bottom: 1px solid #eee; text-align: left; }
    .search-box { margin-bottom: 15px; }
    .copy-btn { cursor: pointer; color: var(--main); margin-left: 5px; font-size: 14px; }
</style>
<script>
    function searchUser() {
        let input = document.getElementById('search').value.toUpperCase();
        let rows = document.querySelectorAll("table tr:not(:first-child)");
        rows.forEach(row => {
            row.style.display = row.innerText.toUpperCase().includes(input) ? "" : "none";
        });
    }
    function copyText(text) {
        navigator.clipboard.writeText(text);
        alert("Copied: " + text);
    }
</script>
'''

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect(url_for("dashboard"))
    return render_template_string(STYLE + '''
    <div class="card" style="margin-top: 50px; text-align: center;">
        <div class="logo">ZIV</div>
        <h2>ZIVPN Manager</h2>
        <p style="color: gray;">IP: {{ip}}</p>
        <form method="post">
            <input name="u" placeholder="Admin Username" required>
            <input name="p" type="password" placeholder="Password" required>
            <button class="btn" type="submit">LOGIN</button>
        </form>
    </div>
    ''', ip=get_ip())

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    today = date.today()
    return render_template_string(STYLE + '''
    <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h3 style="margin:0;">Dashboard</h3>
            <a href="/logout" style="color:gray; font-size:12px;">Logout</a>
        </div>
        <p>Total: {{ count }} Users | IP: {{ ip }}</p>
        
        <form action="/add" method="post" style="background: #fff8f2; padding: 15px; border-radius: 10px;">
            <input name="u" placeholder="Username" required>
            <input name="p" placeholder="Password" required>
            <input name="e" placeholder="Days (e.g. 30)" required>
            <button class="btn" type="submit">+ CREATE ACCOUNT</button>
        </form>

        <input type="text" id="search" onkeyup="searchUser()" placeholder="🔍 Search users..." class="search-box">

        <table>
            <tr><th>User</th><th>Exp</th><th>Status</th><th>Action</th></tr>
            {% for u in users %}
            {% set is_expired = u.expires and u.expires < today_str %}
            <tr>
                <td>{{ u.user }} <span class="copy-btn" onclick="copyText('{{u.user}} {{u.password}}')">📋</span></td>
                <td>{{ u.expires }}</td>
                <td class="{{ 'status-off' if is_expired else 'status-on' }}">
                    {{ 'Expired' if is_expired else 'Active' }}
                </td>
                <td>
                    <a href="/edit/{{ u.user }}" style="color: var(--main); text-decoration: none;">⚙️</a> | 
                    <a href="/delete/{{ u.user }}" class="btn-del" onclick="return confirm('ဖျက်မှာ သေချာလား?')">🗑️</a>
                </td>
            </tr>
            {% endfor %}
        </table>
    </div>
    ''', count=len(users), users=users, ip=get_ip(), today_str=today.strftime("%Y-%m-%d"))

@app.route("/add", methods=["POST"])
def add_user():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    u, p, e = request.form.get("u"), request.form.get("p"), request.form.get("e")
    exp = (date.today() + timedelta(days=int(e))).strftime("%Y-%m-%d") if e.isdigit() else e
    users.append({"user": u, "password": p, "expires": exp})
    save_and_sync(users)
    return redirect(url_for("dashboard"))

@app.route("/delete/<username>")
def delete_user(username):
    if not session.get("auth"): return redirect(url_for("login"))
    users = [u for u in load_users() if u["user"] != username]
    save_and_sync(users)
    return redirect(url_for("dashboard"))

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

# 3. Systemd Service Restart
systemctl restart zivpn-web || (cat <<EOF >/etc/systemd/system/zivpn-web.service
[Unit]
Description=ZIVPN Web Service
After=network.target
[Service]
EnvironmentFile=$ENVF
ExecStart=/usr/bin/python3 /etc/zivpn/web.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now zivpn-web)

echo -e "\e[1;32m✅ အားလုံး အစုံအလင် ပါဝင်တဲ့ Pro Panel ရပါပြီ Bro!\e[0m"
echo -e "Link: http://$(hostname -I | awk '{print $1}'):8080"
