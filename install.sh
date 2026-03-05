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
echo "--- ZiVPN UDP Panel (With Expired Date) ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ Panel မျက်နှာပြင် (index.php) မှာ ရက်သတ်မှတ်ချက် ထည့်မယ်
cat <<EOF > /var/www/html/index.php
<?php
include "config.php";
session_start();

if (!isset(\$_SESSION['login'])) {
    if (isset(\$_POST['user']) && \$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
        \$_SESSION['login'] = true;
    } else {
?>
        <div style="text-align:center; margin-top:50px; font-family:sans-serif;">
            <form method="POST">
                <h2>ZiVPN Admin Login</h2>
                <input type="text" name="user" placeholder="Username" required><br><br>
                <input type="password" name="pass" placeholder="Password" required><br><br>
                <button type="submit">Login</button>
            </form>
        </div>
<?php exit(); }
}

if (isset(\$_POST['create_user'])) {
    \$u = \$_POST['username'];
    \$p = \$_POST['password'];
    \$d = \$_POST['days'];
    
    // သက်တမ်းကုန်မည့်ရက်ကို တွက်ချက်ခြင်း
    \$exp = date('Y-m-d', strtotime("+\$d days"));
    
    // VPS မှာ User ဆောက်ပြီး သက်တမ်းသတ်မှတ်ခြင်း
    shell_exec("sudo useradd -e \$exp -M -s /bin/false \$u && echo '\$u:\$p' | sudo chpasswd");
    
    \$udp_config = "SSH-UDP###\$u:\$p@$MYIP:22";
    \$msg = "User \$u ကို အောင်မြင်စွာ ဆောက်ပြီးပါပြီ! (သက်တမ်းကုန်ရက်: \$exp)";
}
?>

<div style="max-width:500px; margin:auto; font-family:sans-serif; border:1px solid #ddd; padding:20px; border-radius:10px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);">
    <h2 style="text-align:center; color:#333;">ZiVPN UDP Manager</h2>
    <?php if(isset(\$msg)) echo "<p style='color:green; font-weight:bold;'>\$msg</p>"; ?>
    
    <form method="POST">
        <label>Username:</label>
        <input type="text" name="username" placeholder="VPN Username" required style="width:100%; padding:10px; margin-bottom:10px;"><br>
        <label>Password:</label>
        <input type="text" name="password" placeholder="VPN Password" required style="width:100%; padding:10px; margin-bottom:10px;"><br>
        <label>သက်တမ်း (ရက်):</label>
        <select name="days" style="width:100%; padding:10px; margin-bottom:20px;">
            <option value="1">၁ ရက် (Trial)</option>
            <option value="7">၇ ရက် (1 Week)</option>
            <option value="30" selected>၃၀ ရက် (1 Month)</option>
            <option value="90">၉၀ ရက် (3 Months)</option>
            <option value="365">၃၆၅ ရက် (1 Year)</option>
        </select>
        <button type="submit" name="create_user" style="width:100%; padding:12px; background:#28a745; color:white; border:none; border-radius:5px; cursor:pointer;">Create Account</button>
    </form>

    <?php if(isset(\$udp_config)): ?>
        <hr>
        <h4 style="margin-bottom:5px;">ZiVPN UDP Config:</h4>
        <div style="background:#f4f4f4; padding:10px; word-break:break-all; border:1px dashed #666; font-family:monospace;">
            <?php echo \$udp_config; ?>
        </div>
        <p style="font-size:12px; color:red; margin-top:5px;">* ဤ Config ကို ကူးယူပြီး ZiVPN တွင် အသုံးပြုပါ။</p>
    <?php endif; ?>
    
    <br>
    <div style="text-align:right;">
        <a href="?logout" style="color:#888; text-decoration:none; font-size:14px;">Logout</a>
    </div>
</div>
<?php if(isset(\$_GET['logout'])) { session_destroy(); header("Location: index.php"); } ?>
EOF

chown -R www-data:www-data /var/www/html/
service apache2 restart

echo "------------------------------------------"
echo "ZiVPN UDP (With Date) Update ပြီးပါပြီ!"
echo "Link: http://$MYIP"
echo "------------------------------------------"
