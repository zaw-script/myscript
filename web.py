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
                <td>
                    <a href="/del/{{ u.user }}" class="action-links">🗑️</a>
                </td>
            </tr>
            {% endfor %}
        </table>
        <a href="/logout" class="logout">Logout</a>
    </div>''', users=users)
