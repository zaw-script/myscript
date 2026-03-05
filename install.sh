#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget screen -y

# Badvpn-udpgw (UDP Gateway) သွင်းမယ်
wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop71/badvpn/raw/master/bin/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw
screen -dmS udp screen badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

# ၂။ IP Address ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ Admin User/Pass မေးမယ်
echo "--- ZiVPN Professional UDP Panel ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ Professional UI (index.php) ဆောက်မယ်
cat <<EOF > /var/www/html/index.php
<?php
include "config.php";
session_start();

if (isset(\$_GET['action']) && \$_GET['action'] == 'logout') {
    session_destroy();
    header("Location: index.php");
    exit();
}

if (!isset(\$_SESSION['logged_in'])) {
    if (isset(\$_POST['login_btn'])) {
        if (\$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
            \$_SESSION['logged_in'] = true;
            header("Location: index.php");
            exit();
        } else {
            \$error = "Invalid Login Details!";
        }
    }
?>
<!DOCTYPE html>
<html>
<head>
    <title>ZiVPN Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #f0f2f5; font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-box { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.1); width: 320px; text-align: center; }
        .login-box h2 { color: #1a73e8; margin-bottom: 25px; }
        input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #1a73e8; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; }
        button:hover { background: #1557b0; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>ZiVPN Admin</h2>
        <?php if(isset(\$error)) echo "<p style='color:red;'>\$error</p>"; ?>
        <form method="POST">
            <input type="text" name="user" placeholder="Username" required>
            <input type="password" name="pass" placeholder="Password" required>
            <button type="submit" name="login_btn">LOGIN</button>
        </form>
    </div>
</body>
</html>
<?php exit(); } ?>

<!DOCTYPE html>
<html>
<head>
    <title>ZiVPN Panel</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #f8f9fa; font-family: sans-serif; margin: 0; }
        .nav { background: #1a73e8; color: white; padding: 15px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 600px; margin: 20px auto; padding: 20px; }
        .card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
        input, select { width: 100%; padding: 12px; margin: 8px 0 15px 0; border: 1px solid #ddd; border-radius: 5px; box-sizing: border-box; }
        .btn-create { background: #28a745; color: white; border: none; padding: 15px; width: 100%; border-radius: 5px; font-weight: bold; cursor: pointer; }
        .config-box { background: #e9ecef; padding: 15px; border-radius: 5px; margin-top: 20px; word-break: break-all; border-left: 5px solid #28a745; font-family: monospace; }
    </style>
</head>
<body>
    <div class="nav">
        <span><b>ZiVPN UDP PANEL</b></span>
        <a href="?action=logout" style="color: white; text-decoration: none; font-size: 14px;">Logout</a>
    </div>
    <div class="container">
        <div class="card">
            <h3 style="margin-top: 0; color: #333;">Create UDP Account</h3>
            
            <?php
            if (isset(\$_POST['create'])) {
                \$u = \$_POST['user']; \$p = \$_POST['pass']; \$d = \$_POST['days'];
                \$exp = date('Y-m-d', strtotime("+\$d days"));
                shell_exec("sudo useradd -e \$exp -M -s /bin/false \$u && echo '\$u:\$p' | sudo chpasswd");
                
                // ZiVPN UDP SSH Format
                \$config = "SSH-UDP###\$u:\$p@$MYIP:22";
                echo "<p style='color: green;'>Account Created Successfully!</p>";
                echo "<div class='config-box'><b>Config:</b><br>\$config<br><br><b>Expires:</b> \$exp</div>";
            }
            ?>

            <form method="POST">
                <label>Username</label>
                <input type="text" name="user" placeholder="Enter VPN Username" required>
                <label>Password</label>
                <input type="text" name="pass" placeholder="Enter VPN Password" required>
                <label>Validity (Days)</label>
                <select name="days">
                    <option value="1">1 Day (Trial)</option>
                    <option value="7">7 Days</option>
                    <option value="30" selected>30 Days</option>
                </select>
                <button type="submit" name="create" class="btn-create">CREATE ACCOUNT</button>
            </form>
        </div>
    </div>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/html/
service apache2 restart

echo "------------------------------------------"
echo "ZiVPN Professional Panel Update Complete!"
echo "Link: http://$MYIP"
echo "------------------------------------------"
