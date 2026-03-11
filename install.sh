import os, json, datetime
from flask import Flask, render_template_string, request, redirect, session

app = Flask(__name__)
app.secret_key = 'zivpn_secret_key'
USERS_FILE = "/etc/zivpn/users.json"
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, "r") as f: return json.load(f)
    return []

def save_users(users):
    with open(USERS_FILE, "w") as f: json.dump(users, f, indent=2)

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form.get("u") == ADMIN_USER and request.form.get("p") == ADMIN_PASS:
            session["auth"] = True
            return redirect("/dashboard")
    return '''<form method="post">User: <input name="u"><br>Pass: <input name="p" type="password"><br><button>Login</button></form>'''

@app.route("/dashboard")
def dashboard():
    if not session.get("auth"): return redirect("/")
    users = load_users()
    html = '<h2>Dashboard</h2><form action="/add" method="post"><input name="u" placeholder="User"><input name="p" placeholder="Pass"><input name="d" placeholder="Days"><button>Create</button></form><table border=1><tr><th>User</th><th>Pass</th><th>Exp</th><th>Action</th></tr>'
    for u in users:
        html += f'<tr><td>{u["user"]}</td><td>{u["password"]}</td><td>{u["exp"]}</td><td><a href="/del/{u["user"]}">Delete</a></td></tr>'
    return html + '</table><br><a href="/logout">Logout</a>'

@app.route("/add", methods=["POST"])
def add():
    if not session.get("auth"): return redirect("/")
    users = load_users()
    exp = (datetime.datetime.now() + datetime.timedelta(days=int(request.form["d"]))).strftime("%Y-%m-%d")
    users.append({"user": request.form["u"], "password": request.form["p"], "exp": exp})
    save_users(users)
    return redirect("/dashboard")

@app.route("/del/<u_name>")
def delete(u_name):
    if not session.get("auth"): return redirect("/")
    save_users([u for u in load_users() if u["user"] != u_name])
    return redirect("/dashboard")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
