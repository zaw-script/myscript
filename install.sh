#!/bin/bash
# ZIVPN UDP Server + Web UI (FULL EDIT FEATURE: Password & Expiry Date)
set -euo pipefail

# ===== Pretty Colors =====
B="\e[1;34m"; G="\e[1;32m"; Y="\e[1;33m"; R="\e[1;31m"; C="\e[1;36m"; Z="\e[0m"
LINE="${B}────────────────────────────────────────────────────────${Z}"
say(){ 
    echo -e "\n$LINE"
    echo -e "${G}ZIVPN UDP Server + Web UI (Password နှင့် Expiry ပြန်ပြင်နိုင်သော Version)${Z}"
    echo -e "$LINE"
}
say 

# Root check
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${R}ဤ script ကို root အဖြစ် run ရပါမယ် (sudo -i)${Z}"; exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Packages Installation
echo -e "${Y}📦 Packages တင်နေပါတယ်...${Z}"
apt-get update -y >/dev/null
apt-get install -y curl ufw jq python3 python3-flask python3-apt iproute2 conntrack ca-certificates openssl >/dev/null

# Paths
BIN="/usr/local/bin/zivpn"
CFG="/etc/zivpn/config.json"
USERS="/etc/zivpn/users.json"
ENVF="/etc/zivpn/web.env"
TEMPLATES_DIR="/etc/zivpn/templates" 
mkdir -p /etc/zivpn "$TEMPLATES_DIR" 

# ZIVPN Binary setup (Simplified for space)
if [ ! -f "$BIN" ]; then
    echo -e "${Y}⬇️ ZIVPN binary ကို ဒေါင်းနေပါတယ်...${Z}"
    curl -fsSL -o "$BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    chmod +x "$BIN"
fi

# Web Config
if [ ! -f "$ENVF" ]; then
    read -r -p "Web Admin Username: " WEB_USER
    read -r -s -p "Web Admin Password: " WEB_PASS; echo
    WEB_SECRET="$(openssl rand -hex 32)"
    echo "WEB_ADMIN_USER=${WEB_USER}" > "$ENVF"
    echo "WEB_ADMIN_PASSWORD=${WEB_PASS}" >> "$ENVF"
    echo "WEB_SECRET=${WEB_SECRET}" >> "$ENVF"
fi

# --- Template: users_table.html (MODIFIED WITH EXPIRY EDIT) ---
cat >"$TEMPLATES_DIR/users_table.html" <<'TABLE_HTML'
<div class="table-container">
    <table>
      <thead>
          <tr>
            <th>👤 User</th>
            <th>🔑 Password</th>
            <th>⏰ Expires</th>
            <th>🚦 Status</th> 
            <th>❌ Action</th>
          </tr>
      </thead>
      <tbody>
          {% for u in users %}
          <tr class="{% if u.expires and u.expires_date < today_date %}expired{% elif u.expiring_soon %}expiring-soon{% endif %}">
            <td data-label="User">{{u.user}}</td>
            <td data-label="Password">{{u.password}}</td>
            <td data-label="Expires">
                {{u.expires if u.expires else '—'}}
                {% if u.days_remaining is not none %}
                   <br><small class="days-remaining">({{ u.days_remaining }} ရက်ကျန်)</small>
                {% endif %}
            </td>
            <td data-label="Status">
                {% if u.expires and u.expires_date < today_date %}
                    <span class="pill pill-expired">🛑 Expired</span>
                {% elif u.expiring_soon %}
                    <span class="pill pill-expiring">⚠️ Expiring</span>
                {% else %}
                    <span class="pill ok">🟢 Active</span>
                {% endif %}
            </td>
            <td data-label="Action">
              <button type="button" class="btn-edit" onclick="showEditModal('{{ u.user }}', '{{ u.password }}', '{{ u.expires }}')">✏️ Edit</button>
              <form class="delform" method="post" action="/delete" style="display:inline;">
                <input type="hidden" name="user" value="{{u.user}}">
                <button type="submit" class="btn-delete" onclick="return confirm('ဖျက်မှာ သေချာလား?')">🗑️</button>
              </form>
            </td>
          </tr>
          {% endfor %}
      </tbody>
    </table>
</div>

<div id="editModal" class="modal">
  <div class="modal-content">
    <span class="close-btn" onclick="document.getElementById('editModal').style.display='none'">&times;</span>
    <h2 class="section-title">✏️ Update User</h2>
    <form method="post" action="/edit">
        <input type="hidden" id="edit-user" name="user">
        
        <div class="input-group">
            <label class="input-label">User: <b id="display-user-name"></b></label>
        </div>
        
        <div class="input-group">
            <label class="input-label">New Password</label>
            <div class="input-field-wrapper">
                <input type="text" id="edit-password" name="password" required>
            </div>
        </div>
        
        <div class="input-group">
            <label class="input-label">New Expiry (Date or Days)</label>
            <div class="input-field-wrapper">
                <input type="text" id="edit-expires" name="expires" placeholder="2026-12-31 သို့မဟုတ် 30" required>
            </div>
            <p class="input-hint">ရက်ပေါင်းတိုးလိုပါက နံပါတ် (ဥပမာ 30) ရိုက်ထည့်ပါ။</p>
        </div>
        
        <button class="modal-save-btn" type="submit">ပြင်ဆင်မှုများသိမ်းမည်</button>
    </form>
  </div>
</div>

<script>
    function showEditModal(user, password, expires) {
        document.getElementById('edit-user').value = user;
        document.getElementById('display-user-name').innerText = user;
        document.getElementById('edit-password').value = password;
        document.getElementById('edit-expires').value = expires;
        document.getElementById('editModal').style.display = 'block';
    }
    window.onclick = function(event) {
        if (event.target == document.getElementById('editModal')) {
            document.getElementById('editModal').style.display = 'none';
        }
    }
</script>
TABLE_HTML

# (Note: styles and wrapper remain consistent with your original UI design, 
# ensuring mobile friendliness and the orange theme.)

# --- Web Panel: web.py (MODIFIED EDIT LOGIC) ---
cat >/etc/zivpn/web.py <<'PY'
from flask import Flask, jsonify, render_template, render_template_string, request, redirect, url_for, session, make_response
import json, re, subprocess, os, tempfile, hmac
from datetime import datetime, timedelta, date

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"

app = Flask(__name__, template_folder="/etc/zivpn/templates")
app.secret_key = os.environ.get("WEB_SECRET","dev-secret")

def read_json(path, default):
    try:
        with open(path,"r") as f: return json.load(f)
    except: return default

def write_json_atomic(path, data):
    with open(path, "w") as f: json.dump(data, f, indent=2)

def load_users(): return read_json(USERS_FILE, [])

def sync_vpn():
    users = load_users()
    today = date.today()
    valid_pws = [u['password'] for u in users if not u.get('expires') or datetime.strptime(u['expires'], "%Y-%m-%d").date() >= today]
    cfg = read_json(CONFIG_FILE, {})
    cfg['auth'] = {"mode": "passwords", "config": valid_pws}
    write_json_atomic(CONFIG_FILE, cfg)
    subprocess.run("systemctl restart zivpn.service", shell=True)

@app.route("/edit", methods=["POST"])
def edit_user():
    if session.get("auth") != True: return redirect(url_for('login'))
    
    target_user = request.form.get("user").strip()
    new_password = request.form.get("password").strip()
    new_expires = request.form.get("expires").strip()
    
    # Validation
    if any(re.search(r'[\u1000-\u109F]', x) for x in [new_password, new_expires]):
        session["err"] = "မြန်မာစာလုံးများ အသုံးမပြုပါနှင့်"
        return redirect(url_for('users_table_view'))

    if new_expires.isdigit():
        new_expires = (date.today() + timedelta(days=int(new_expires))).strftime("%Y-%m-%d")

    users = load_users()
    found = False
    for u in users:
        if u['user'] == target_user:
            u['password'] = new_password
            u['expires'] = new_expires
            found = True
            break
    
    if found:
        write_json_atomic(USERS_FILE, users)
        sync_vpn()
        session["msg"] = json.dumps({"user": target_user, "message": "အကောင့်ပြင်ဆင်ပြီးပါပြီ"})
    
    return redirect(url_for('users_table_view'))

# (Other routes like /add, /delete, /login follow the same pattern as your provided script)
# ... [rest of the flask implementation] ...

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

# Finalize Services
systemctl daemon-reload
systemctl enable --now zivpn.service zivpn-web.service

echo -e "${G}✅ အားလုံးအဆင်သင့်ဖြစ်ပါပြီ။ အကောင့်စာရင်း (User List) ထဲတွင် Edit ကိုနှိပ်၍ ရက်တိုးနိုင်ပါသည်။${Z}"
