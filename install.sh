#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget screen -y

# Badvpn-udpgw သွင်းမယ်
wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop71/badvpn/raw/master/bin/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw
screen -dmS udp screen badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

# ၂။ IP Address ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ Admin User/Pass မေးမယ်
echo "--- ZiVPN Professional UI Setup ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ ညီလေးပြတဲ့ ပုံစံအတိုင်း UI ကို ဆောက်မယ်
cat <<EOF > /var/www/html/index.php
<?php
session_start();
include "config.php";

if (isset(\$_GET['action']) && \$_GET['action'] == 'logout') {
    session_destroy();
    header("Location: index.php");
    exit();
}

if (!isset(\$_SESSION['auth'])) {
    if (isset(\$_POST['login_btn'])) {
        if (\$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
            \$_SESSION['auth'] = true;
            header("Location: index.php");
            exit();
        } else { \$error = "အချက်အလက် မှားယွင်းနေပါသည်။"; }
    }
?>
<!DOCTYPE html>
<html>
<head>
    <title>ZiVPN Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #eef2f7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-box { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); width: 100%; max-width: 350px; text-align: center; }
        .login-box h2 { color: #333; margin-bottom: 30px; }
        input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; outline: none; }
        button { width: 100%; padding: 12px; background: #007bff; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; font-size: 16px; transition: 0.3s; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>ZiVPN PANEL</h2>
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
    <title>ZiVPN Admin Panel</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #f4f7f6; font-family: sans-serif; margin: 0; }
        .header { background: #343a40; color: white; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 500px; margin: 30px auto; padding: 0 15px; }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .card h3 { margin-top: 0; color: #333; border-bottom: 2px solid #f4f7f6; padding-bottom: 10px; }
        label { font-weight: bold; display: block; margin-top: 15px; color: #555; }
        input, select { width: 100%; padding: 12px; margin-top: 5px; border: 1px solid #ccc; border-radius: 6px; box-sizing: border-box; }
        .btn-submit { background: #28a745; color: white; border: none; padding: 15px; width: 100%; border-radius: 6px; font-weight: bold; cursor: pointer; margin-top: 20px; font-size: 16px; }
        
        /* ညီလေးပြထားတဲ့ ပုံစံအတိုင်း Result Box */
        .result-container { background: #ffffff; border: 1px solid #28a745; border-radius: 10px; margin-top: 25px; overflow: hidden; }
        .result-header { background: #28a745; color: white; padding: 10px; font-weight: bold; text-align: center; }
        .result-body { padding: 15px; font-family: monospace; font-size: 14px; color: #333; }
        .info-row { display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee; }
        .config-text { background: #f8f9fa; padding: 10px; border-radius: 5px; margin-top: 10px; word-break: break-all; color: #d63384; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="header">
        <span><b>ZIVPN UDP MANAGER</b></span>
        <a href="?action=logout" style="color: #ffc107; text-decoration: none; font-weight: bold;">Logout</a>
    </div>
    <div class="container">
        <div class="card">
            <h3>Create New Account</h3>
            <form method="POST">
                <label>Username</label>
                <input type="text" name="user" placeholder="Account Username" required>
                <label>Password</label>
                <input type="text" name="pass" placeholder="Account Password" required>
                <label>Duration</label>
                <select name="days">
                    <option value="1">1 Day (Trial)</option>
                    <option value="7">7 Days (1 Week)</option>
                    <option value="30" selected>30 Days (1 Month)</option>
                </select>
                <button type="submit" name="create" class="btn-submit">CREATE ACCOUNT</button>
            </form>

            <?php
            if (isset(\$_POST['create'])) {
                \$u = \$_POST['user']; \$p = \$_POST['pass']; \$d = \$_POST['days'];
                \$exp = date('Y-m-d', strtotime("+\$d days"));
                shell_exec("sudo useradd -e \$exp -M -s /bin/false \$u && echo '\$u:\$p' | sudo chpasswd");
                \$config = "SSH-UDP###\$u:\$p@$MYIP:22";
            ?>
                <div class="result-container">
                    <div class="result-header">ACCOUNT DETAILS</div>
                    <div class="result-body">
                        <div class="info-row"><span>Username:</span> <b><?php echo \$u; ?></b></div>
                        <div class="info-row"><span>Password:</span> <b><?php echo \$p; ?></b></div>
                        <div class="info-row"><span>Expired:</span> <b><?php echo \$exp; ?></b></div>
                        <div style="margin-top:10px; font-weight:bold;">Config ZiVPN:</div>
                        <div class="config-text"><?php echo \$config; ?></div>
                        <p style="font-size:11px; color:#666; margin-top:10px; text-align:center;">Copy the config above and import to ZiVPN App.</p>
                    </div>
                </div>
            <?php } ?>
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
