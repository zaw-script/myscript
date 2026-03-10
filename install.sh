#!/bin/bash
# ZIVPN Final Stable Fix
cat >/etc/zivpn/web.py <<'PY'
import os, json, subprocess, socket
from flask import Flask, render_template_string, request, redirect, url_for, session
from datetime import datetime, timedelta, date

app = Flask(__name__)
app.secret_key = os.environ.get("WEB_SECRET", "default_secret_key")

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD")
CONTACT_LINK = os.environ.get("WEB_CONTACT_LINK", "#")

def get_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except: return "IP Unknown"

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
    body { font-family: sans-serif; background: #f4f7f6; margin: 0; padding: 20px; text-align: center; }
    .card { background: white; padding: 25px; border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); max-width: 450px; margin: auto; }
    .logo-circle { background: white; width: 80px; height: 80px; border-radius: 50%; border: 4px solid #ff851b; display: flex; align-items: center; justify-content: center; margin: 0 auto 10px; }
    .logo-circle span { color: #ff851b; font-size: 24px; font-weight: bold; border: 2px solid #ff851b; border-radius: 50%; padding: 8px; }
    input { width: 90%; padding: 12px; margin: 8px 0; border: 1px solid #ddd; border-radius: 10px; font-size: 14px; }
    .btn { background: #ff851b; color: white; border: none; padding: 12px; width: 95%; border-radius: 10px; font-size: 16px; font-weight: bold; cursor: pointer; margin-top: 10px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 13px; text-align: left; }
    th, td { padding: 10px; border-bottom: 1px solid #eee; }
    .ip-box { color: #ff851b; font-weight: bold; margin: 10px 0; font-size: 15px; }
    .user-count { background: #fff2e6; padding: 10px; border-radius: 10px; font-weight: bold; margin-bottom: 15px; color: #ff851b; }
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
        <h2 style="margin:5px;">ZIVPN Panel</h2>
        <div class="ip-box">Server IP: {{ip}}</div>
        <form method="post">
            <input name="u" placeholder="👤 Admin Username" required>
            <input name="p" type="password" placeholder="🔒 Password" required>
            <button class="btn" type="submit">Login</button>
        </form>
        <a href="{{ contact }}" target="_blank" style="color:#ff851b; text-decoration:none; display:block; margin-top:15px;">💬 Admin ကို ဆက်သွယ်ပါ</a>
    </div>
    ''', ip=get_ip(), contact=CONTACT_LINK)

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    return render_template_string(STYLE + '''
    <div class="card">
        <h3 style="margin:0;">User Dashboard</h3>
        <div class="ip-box">Server IP: {{ip}}</div>
        <div class="user-count">👥 လက်ရှိ Member User စုစုပေါင်း - {{ users|length }} ယောက်</div>
        <form action="/add" method="post">
            <input name="u" placeholder="👤 Username" required>
            <input name="p" placeholder="🔑 Password" required>
            <input name="e" placeholder="📅 Days (e.g. 30)" required>
            <button class="btn" type="submit">Create Account</button>
        </form>
        <hr style="margin:20px 0; border:0; border-top:1px solid #eee;">
        <table>
            <tr><th>User</th><th>Pass</th><th>Exp</th><th>Action</th></tr>
            {% for u in users %}
            <tr>
                <td>{{ u.user }}</td>
                <td><code>{{ u.password }}</code></td>
                <td>{{ u.expires }}</td>
                <td>
                    <a href="/edit/{{ u.user }}" style="color:#ff851b; text-decoration:none;">[ပြင်ရန်]</a> |
                    <a href="/delete/{{ u.user }}" style="color:red; text-decoration:none;" onclick="return confirm('ဖျက်မှာလား?')">🗑️</a>
                </td>
            </tr>
            {% endfor %}
        </table>
        <br><a href="/logout" style="color:gray; font-size:12px; text-decoration:none;">Logout</a>
    </div>
    ''', users=users, ip=get_ip())

@app.route("/edit/<username>", methods=["GET", "POST"])
def edit_user(username):
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    user = next((u for u in users if u["user"] == username), None)
    if not user: return redirect(url_for("dashboard"))
    if request.method == "POST":
        user["password"] = request.form.get("p")
        e = request.form.get("e")
        user["expires"] = (date.today() + timedelta(days=int(e))).strftime("%Y-%m-%d") if e.isdigit() else e
        save_and_sync(users)
        return redirect(url_for("dashboard"))
    return render_template_string(STYLE + f'''
    <div class="card">
        <h3>📝 ပြင်ဆင်ရန်: {username}</h3>
        <form method="post">
            <input name="p" value="{user['password']}" placeholder="Password" required>
            <input name="e" value="{user['expires']}" placeholder="Days or YYYY-MM-DD" required>
            <button class="btn" type="submit">Update Account</button>
        </form>
        <br><a href="/dashboard" style="color:gray; text-decoration:none;">Back to Dashboard</a>
    </div>
    ''')

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
systemctl restart zivpn-web
echo "Panel updated successfully."
