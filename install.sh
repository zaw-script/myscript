#!/bin/bash
# ZIVPN Fix Script: Login & Password Column Fix
set -euo pipefail

# 1. Login အချက်အလက်သတ်မှတ်ခြင်း
ENVF="/etc/zivpn/web.env"
# အရင်ရှိပြီးသား Login ကို ဖျက်ပြီး အသစ်ပြန်တောင်းရန်
rm -f "$ENVF"

echo -e "\e[1;33m🔒 Web Admin Login အသစ်သတ်မှတ်ပေးပါ\e[0m"
read -r -p "Admin Username: " WEB_USER
read -r -s -p "Admin Password: " WEB_PASS; echo
echo "WEB_ADMIN_USER=${WEB_USER}" > "$ENVF"
echo "WEB_ADMIN_PASSWORD=${WEB_PASS}" >> "$ENVF"
echo "WEB_SECRET=$(openssl rand -hex 32)" >> "$ENVF"

# 2. Python Script ကို ပြင်ဆင်ခြင်း (Pass Column ပြန်ထည့်ထားသည်)
cat >/etc/zivpn/web.py <<'PY'
import os, json, subprocess
from flask import Flask, render_template_string, request, redirect, url_for, session
from datetime import datetime, date, timedelta

app = Flask(__name__)
app.secret_key = os.environ.get("WEB_SECRET")

USERS_FILE = "/etc/zivpn/users.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD")

def load_users():
    try:
        if os.path.exists(USERS_FILE):
            with open(USERS_FILE, "r") as f: return json.load(f)
    except: pass
    return []

def save_users(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)

STYLE = '''
<style>
    body { font-family: sans-serif; background: #f4f7f6; padding: 20px; }
    .card { background: white; padding: 25px; border-radius: 15px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); max-width: 600px; margin: auto; }
    input { width: 100%; padding: 10px; margin: 5px 0 15px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; }
    .btn { background: #ff851b; color: white; border: none; padding: 12px; width: 100%; border-radius: 8px; cursor: pointer; font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { text-align: left; padding: 10px; border-bottom: 1px solid #eee; }
    .status-active { color: #2ecc40; font-weight: bold; }
    .btn-del { background: #ff4136; color: white; padding: 5px 10px; border-radius: 5px; text-decoration: none; font-size: 12px; }
</style>
'''

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect(url_for("dashboard"))
    return render_template_string(STYLE + '''
    <div class="card" style="text-align: center; margin-top: 50px;">
        <h2>ZIVPN Manager Login</h2>
        <form method="post">
            <input name="u" placeholder="Admin Username" required>
            <input name="p" type="password" placeholder="Password" required>
            <button class="btn" type="submit">LOGIN</button>
        </form>
    </div>
    ''')

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    return render_template_string(STYLE + '''
    <div class="card">
        <h3>Dashboard <a href="/logout" style="float:right; font-size:12px; color:gray;">Logout</a></h3>
        <form action="/add" method="post">
            <input name="u" placeholder="Username" required>
            <input name="p" placeholder="Password" required>
            <input name="d" placeholder="Days (e.g. 30)" required>
            <button class="btn" type="submit">+ CREATE ACCOUNT</button>
        </form>
        <table>
            <tr><th>User</th><th>Pass</th><th>Exp</th><th>Action</th></tr>
            {% for u in users %}
            <tr>
                <td>{{ u.user }}</td>
                <td><code>{{ u.password }}</code></td>
                <td>{{ u.expires }}</td>
                <td><a href="/delete/{{ u.user }}" class="btn-del">🗑️</a></td>
            </tr>
            {% endfor %}
        </table>
    </div>
    ''', users=users)

@app.route("/add", methods=["POST"])
def add_user():
    if not session.get("auth"): return redirect(url_for("login"))
    users = load_users()
    u, p, d = request.form.get("u"), request.form.get("p"), request.form.get("d")
    exp = (date.today() + timedelta(days=int(d))).strftime("%Y-%m-%d")
    users.append({"user": u, "password": p, "expires": exp})
    save_users(users)
    return redirect(url_for("dashboard"))

@app.route("/delete/<username>")
def delete_user(username):
    if not session.get("auth"): return redirect(url_for("login"))
    users = [u for u in load_users() if u["user"] != username]
    save_users(users)
    return redirect(url_for("dashboard"))

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

# 3. Service ပြန်စတင်ခြင်း
systemctl daemon-reload
systemctl restart zivpn-web

echo -e "\e[1;32m✅ အားလုံးပြင်ဆင်ပြီးပါပြီ Bro!\e[0m"
echo -e "Link: http://$(hostname -I | awk '{print $1}'):8080"
