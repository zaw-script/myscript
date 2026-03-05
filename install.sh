#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ် (UDP GW ပါ တစ်ခါတည်း လုပ်မယ်)
apt update -y
apt install apache2 php libapache2-mod-php wget screen -y

# Badvpn-udpgw သွင်းမယ် (UDP သုံးဖို့အတွက်)
wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop71/badvpn/raw/master/bin/badvpn-udpgw"
chmod +x /usr/bin/badvpn-udpgw
screen -dmS udp screen badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000

# ၂။ IP Address ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ Admin User/Pass မေးမယ်
echo "--- ZiVPN UDP Panel Setup ---"
read -p "Admin Username ပေးပါ: " adm_user
read -p "Admin Password ပေးပါ: " adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ Panel မျက်နှာပြင် (index.php) မှာ UDP Config ထုတ်တဲ့စနစ် ထည့်မယ်
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
    shell_exec("sudo useradd -M -s /bin/false \$u && echo '\$u:\$p' | sudo chpasswd");
    
    // ZiVPN UDP SSH Config Format
    \$udp_config = "SSH-UDP###\$u:\$p@$MYIP:22";
    \$msg = "User \$u ကို အောင်မြင်စွာ ဆောက်ပြီးပါပြီ!";
}
?>

<div style="max-width:500px; margin:auto; font-family:sans-serif; border:1px solid #ddd; padding:20px; border-radius:10px;">
    <h2 style="text-align:center; color:#333;">ZiVPN UDP Panel</h2>
    <?php if(isset(\$msg)) echo "<p style='color:green;'>\$msg</p>"; ?>
    
    <form method="POST">
        <input type="text" name="username" placeholder="VPN Username" required style="width:100%; padding:10px; margin-bottom:10px;"><br>
        <input type="text" name="password" placeholder="VPN Password" required style="width:100%; padding:10px; margin-bottom:10px;"><br>
        <button type="submit" name="create_user" style="width:100%; padding:10px; background:#28a745; color:white; border:none; border-radius:5px;">Create UDP Account</button>
    </form>

    <?php if(isset(\$udp_config)): ?>
        <hr>
        <h4>ZiVPN UDP Config:</h4>
        <div style="background:#f4f4f4; padding:10px; word-break:break-all; border:1px dashed #666;">
            <?php echo \$udp_config; ?>
        </div>
        <p style="font-size:12px; color:red;">* ဤစာသားကို Copy ကူးပြီး ZiVPN ထဲတွင် Paste လုပ်သုံးပါ။</p>
    <?php endif; ?>
    
    <br><a href="?logout" style="color:#666; text-decoration:none;">Logout</a>
</div>
<?php if(isset(\$_GET['logout'])) { session_destroy(); header("Location: index.php"); } ?>
EOF

chown -R www-data:www-data /var/www/html/
service apache2 restart

echo "------------------------------------------"
echo "ZiVPN UDP Panel Update ပြီးပါပြီ!"
echo "Link: http://$MYIP"
echo "------------------------------------------"
