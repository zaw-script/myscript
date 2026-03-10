import os, json, subprocess, socket
from flask import Flask, render_template_string, request, redirect, url_for, session
from datetime import datetime, timedelta, date

app = Flask(__name__)
app.secret_key = os.urandom(24)

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
    except: return "127.0.0.1"

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, "r") as f: return json.load(f)
    return []

def save_and_sync(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)
    valid = [u['password'] for u in users]
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f: cfg = json.load(f)
        cfg['auth']['config'] = valid
        with open(CONFIG_FILE, "w") as f: json.dump(cfg, f, indent=2)
        subprocess.run(["systemctl", "restart", "zivpn"], check=False)

STYLE = '''<style>
body{background:#f4f7f6;text-align:center;padding:20px;font-family:sans-serif}
.card{background:white;padding:20px;border-radius:15px;max-width:450px;margin:auto;box-shadow:0 4px 10px rgba(0,0,0,0.1)}
input{width:90%;padding:10px;margin:5px 0;border:1px solid #ddd;border-radius:5px}
.btn{width:92%;padding:10px;background:#ff851b;border:none;color:white;cursor:pointer;border-radius:5px;font-weight:bold}
table{width:100%;border-collapse:collapse;margin-top:20px}
th,td{padding:10px;border-bottom:1px solid #eee;font-size:13px}
</style>'''

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect("/dashboard")
    return render_template_string(STYLE + '''
    <div class="card"><h2>Login</h2><form method="post">
    <input name="u" placeholder="User" required><br>
    <input name="p" type="password" placeholder="Pass" required><br>
    <button class="btn" type="submit">Login</button></form></div>''')

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect("/")
    users = load_users()
    user_count = len(users)
    return render_template_string(STYLE + '''
    <div class="card"><h3>Dashboard</h3>
    <div style="background:#fff2e6;padding:10px;margin:10px 0;color:#ff851b;font-weight:bold">
    👥 စုစုပေါင်း Member: {{ user_count }} ယောက်</div>
    <form action="/add" method="post">
    <input name="u" placeholder="User" required><br>
    <input name="p" placeholder="Pass" required><br>
    <input name="e" placeholder="Days" required><br>
    <button class="btn" type="submit">Create</button></form>
    <table><tr><th>User</th><th>Pass</th><th>Action</th></tr>
    {% for u in users %}<tr><td>{{u.user}}</td><td>{{u.password}}</td>
    <td><a href="/del/{{u.user}}" style="color:red">Delete</a></td></tr>{% endfor %}
    </table><br><a href="/logout">Logout</a></div>''', users=users, user_count=user_count)

@app.route("/add", methods=["POST"])
def add():
    users = load_users()
    users.append({"user": request.form.get("u"), "password": request.form.get("p"), "expires": request.form.get("e")})
    save_and_sync(users)
    return redirect("/dashboard")

@app.route("/del/<u_name>")
def delete(u_name):
    users = [u for u in load_users() if u["user"] != u_name]
    save_and_sync(users)
    return redirect("/dashboard")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

if __name__ == "__main__": app.run(host="0.0.0.0", port=8080)
