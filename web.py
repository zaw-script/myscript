import os, json, subprocess, socket
from flask import Flask, render_template_string, request, redirect, url_for, session

app = Flask(__name__)
app.secret_key = os.urandom(24)

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
ADMIN_USER = os.environ.get("WEB_ADMIN_USER", "admin")
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD", "admin123")

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, "r") as f: return json.load(f)
    return []

@app.route("/")
def dashboard():
    users = load_users()
    user_count = len(users)
    return f"Dashboard - Members: {user_count}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
