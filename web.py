import os, json, datetime
from flask import Flask, render_template_string, request, redirect, url_for, session

# လိုအပ်တဲ့ Variables များ
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"
ADMIN_CONTACT = "https://t.me/your_username"

app = Flask(__name__)
app.secret_key = os.urandom(24)

USERS_FILE = "/etc/zivpn/users.json"

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, "r") as f: return json.load(f)
    return []

def save_users(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)

STYLE = '''
<style>
    body { background: #f4f7f6; font-family: sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
    .card { background: white; padding: 25px; border-radius: 15px; width: 90%; max-width: 400px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; }
    .logo-circle { width: 60px; height: 60px; border: 3px solid #ff851b; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 15px; color: #ff851b; font-weight: bold; font-size: 20px; }
    h2 { color: #333; margin-bottom: 5px; font-size: 18px; }
    .server-ip { color: #ff851b; font-size: 12px; margin-bottom: 20px; }
    .member-box { background: #fff2e6; color: #ff851b; padding: 12px; border-radius: 8px; font-weight: bold; margin-bottom: 20px; font-size: 14px; }
    input { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #eee; border-radius: 8px; box-sizing: border-box; background: #fafafa; }
    .btn { width: 100%; padding: 12px; background: #ff851b; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; margin-top: 10px; }
    table { width: 100%; margin-top: 20px; border-collapse: collapse; font-size: 12px; }
    th { color: #666; padding: 10px; border-bottom: 2px solid #eee; text-align: left; }
    td { padding: 10px; border-bottom: 1px solid #eee; text-align: left; }
    .action-links { color: #ff851b; text-decoration: none; margin: 0 5px; }
    .logout { display: block; margin-top: 20px; color: #999; text-decoration: none; font-size: 12px; }
</style>
'''

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect("/dashboard")
    return render_template_string(STYLE + '''
    <div class="card">
        <div class="logo-circle">ZIV</div>
        <h2>ZIVPN Panel</h2>
        <div class="server-ip">Server IP: 43.229.132.141</div>
        <form method="post">
            <input name="u" placeholder="👤 Admin Username" required>
            <input name="p" type="password" placeholder="🔒 Password" required>
            <button class="btn" type="submit">Login</button>
        </form>
        <p style="font-size: 13px; margin-top: 20px;">
            💬 Admin ကို ဆက်သွယ်ရန်: <a href="''' + ADMIN_CONTACT + '''" style="color: #ff851b;">Click Here</a>
        </p>
    </div>''')

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect("/")
    users = load_users()
    return render_template_string(STYLE + '''
    <div class="card" style="max-width: 500px;">
        <h2>User Dashboard</h2>
        <div class="member-box">👥 စုစုပေါင်း Member: {{ users|length }} ယောက်</div>
        <form action="/add" method="post">
            <input name="u" placeholder="👤 Username" required>
            <input name="p" placeholder="🔑 Password" required>
            <input name="d" placeholder="📅 Days (e.g. 30)" required>
            <button class="btn" type="submit">Create Account</button>
        </form>
        <table>
            <tr><th>User</th><th>Pass</th><th>Exp</th><th>Action</th></tr>
            {% for u in users %}
            <tr>
                <td>{{ u.user }}</td>
                <td>{{ u.password }}</td>
                <td>{{ u.exp }}</td>
                <td><a href="/del/{{ u.user }}" class="action-links">🗑️</a></td>
            </tr>
            {% endfor %}
        </table>
        <a href="/logout" class="logout">Logout</a>
    </div>''', users=users)

@app.route("/add", methods=["POST"])
def add():
    if not session.get("auth"): return redirect("/")
    users = load_users()
    days = int(request.form.get("d", 30))
    exp_date = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
    users.append({"user": request.form.get("u"), "password": request.form.get("p"), "exp": exp_date})
    save_users(users)
    return redirect("/dashboard")

@app.route("/del/<u_name>")
def delete(u_name):
    if not session.get("auth"): return redirect("/")
    users = [u for u in load_users() if u["user"] != u_name]
    save_users(users)
    return redirect("/dashboard")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
