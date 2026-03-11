import os, json
from flask import Flask, render_template_string

app = Flask(__name__)

USERS_FILE = "/etc/zivpn/users.json"

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, "r") as f:
            return json.load(f)
    return []

@app.route("/")
def dashboard():
    users = load_users()
    user_count = len(users)
    
    # ဒီနေရာမှာ အရင်ကလို Design လှလှလေး ထည့်ထားပါတယ်
    STYLE = '''
    <style>
        body { background: #f4f7f6; text-align: center; padding: 50px; font-family: sans-serif; }
        .card { background: white; padding: 40px; border-radius: 15px; max-width: 400px; margin: auto; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        h3 { color: #333; }
        .count-box { background: #ff851b; padding: 20px; border-radius: 10px; color: white; font-size: 24px; font-weight: bold; margin-top: 20px; }
    </style>
    '''
    
    HTML = f'''
    {STYLE}
    <div class="card">
        <h3>ZIVPN Admin Dashboard</h3>
        <p>Current System Status</p>
        <div class="count-box">
            👥 စုစုပေါင်း Member: {user_count} ယောက်
        </div>
    </div>
    '''
    return render_template_string(HTML)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
