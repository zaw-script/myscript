#!/bin/bash

# ၁။ လိုအပ်တာတွေ သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget screen -y

# UDP Gateway သွင်းမယ်
wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop71/badvpn/raw/master/bin/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw
screen -dmS udp screen badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

# ၂။ IP Address ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ Admin User/Pass မေးမယ်
echo "--- ZiVPN UDP Panel (Secure Login) ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ Panel မျက်နှာပြင် (index.php) ကို စနစ်တကျ ပြန်ဆောက်မယ်
cat <<EOF > /var/www/html/index.php
<?php
include "config.php";
session_start();

// Logout လုပ်ရန်
if (isset(\$_GET['action']) && \$_GET['action'] == 'logout') {
    session_destroy();
    header("Location: index.php");
    exit();
}

// Login စစ်ဆေးခြင်း
if (!isset(\$_SESSION['logged_in'])) {
    if (isset(\$_POST['login_btn'])) {
        if (\$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
            \$_SESSION['logged_in'] = true;
            header("Location: index.php");
            exit();
        } else {
            \$error = "Username သို့မဟုတ် Password မှားနေပါသည်။";
        }
    }
?>
    <div style="max-width:350px; margin:100px auto; font-family:sans-serif; border:1px solid #ddd; padding:30px; border-radius:15px; box-shadow: 0 5px 15px rgba(0,0,0,0.2);">
        <h2 style="text-align:center;">Admin Login</h2>
        <?php if(isset(\$error)) echo "<p style='color:red; text-align:center;'>\$error</p>"; ?>
        <form method="POST">
            <input type="text" name="user" placeholder="Admin Username" required style="width:100%; padding:12px; margin-bottom:15px; border-radius:5px; border:1px solid #ccc; box-sizing: border-box;"><br>
            <input type="password" name="pass" placeholder="Admin Password" required style="width:100%; padding:12px; margin-bottom:15px; border-radius:5px; border:1px solid #ccc; box-sizing: border-box;"><br>
            <button type="submit" name="login_btn" style="width:100%; padding:12px; background:#007bff; color:white; border:none; border-radius:5px; cursor:pointer; font-weight:bold;">Login</button>
        </form>
    </div>
<?php
    exit();
}

// အကောင့်ဆောက်ခြင်းအပိုင်း (Login ဝင်ပြီးမှ မြင်ရမည်)
if (isset(\$_POST['create_user'])) {
    \$u = \$_POST['username'];
    \$p = \$_POST['password'];
    \$d = \$_POST['days'];
    \$exp = date('Y-m-d', strtotime("+\$d days"));
    
    shell_exec("sudo useradd -e \$exp -M -s /bin/false \$u && echo '\$u:\$p' | sudo chpasswd");
    
    \$udp_config = "SSH-UDP###\$u:\$p@$MYIP:22";
    \$msg = "အောင်မြင်သည်! User: \$u (Exp: \$exp)";
}
?>

<div style="max-width:500px; margin:50px auto; font-family:sans-serif; border:1px solid #ddd; padding:20px; border-radius:10px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);">
    <div style="display:flex; justify-content:space-between; align-items:center;">
        <h2 style="color:#333;">ZiVPN Manager</h2>
        <a href="?action=logout" style="color:red; text-decoration:none; font-weight:bold;">Logout</a>
    </div>
    <hr>
    <?php if(isset(\$msg)) echo "<p style='color:green; font-weight:bold; text-align:center;'>\$msg</p>"; ?>
    
    <form method="POST">
        <label>VPN Username:</label>
        <input type="text" name="username" placeholder="Username" required style="width:100%; padding:10px; margin:10px 0; border:1px solid #ccc; border-radius:5px; box-sizing: border-box;">
        <label>VPN Password:</label>
        <input type="text" name="password" placeholder="Password" required style="width:100%; padding:10px; margin:10px 0; border:1px solid #ccc; border-radius:5px; box-sizing: border-box;">
        <label>သက်တမ်း (ရက်):</label>
        <select name="days" style="width:100%; padding:10px; margin:10px 0; border:1px solid #ccc; border-radius:5px;">
            <option value="1">၁ ရက် (Trial)</option>
            <option value="7">၇ ရက် (1 Week)</option>
            <option value="30" selected>၃၀ ရက် (1 Month)</option>
            <option value="90">၉၀ ရက် (3 Months)</option>
        </select>
        <button type="submit" name="create_user" style="width:100%; padding:12px; background:#28a745; color:white; border:none; border-radius:5px; cursor:pointer; font-weight:bold; margin-top:10px;">Create Account</button>
    </form>

    <?php if(isset(\$udp_config)): ?>
        <hr>
        <h4 style="margin-bottom:5px;">ZiVPN UDP Config:</h4>
        <div style="background:#f4f4f4; padding:15px; word-break:break-all; border:1px dashed #666; font-family:monospace; border-radius:5px;">
            <?php echo \$udp_config; ?>
        </div>
        <p style="font-size:12px; color:blue; margin-top:5px; text-align:center;">* Copy ကူးပြီး ZiVPN ထဲတွင် သုံးပါ *</p>
    <?php endif; ?>
</div>
EOF

chown -R www-data:www-data /var/www/html/
service apache2 restart

echo "------------------------------------------"
echo "ZiVPN Panel (Login Fixed) Update ပြီးပါပြီ!"
echo "Link: http://$MYIP"
echo "------------------------------------------"
