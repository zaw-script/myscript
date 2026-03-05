#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget -y

# ၂။ IP Address ကို ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ User နဲ့ Pass ကို မရမက မေးမယ့်အပိုင်း
echo "--- VPN Panel Admin Setup ---"

# Username မေးမယ် (မရိုက်မချင်း ရှေ့မသွားအောင် လုပ်ထားတယ်)
while [ -z "$adm_user" ]; do
    read -p "Admin Username ပေးပါ: " adm_user
done

# Password မေးမယ်
while [ -z "$adm_pass" ]; do
    read -p "Admin Password ပေးပါ: " adm_pass
done

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php
chmod 644 /var/www/html/config.php

# ၅။ Login Page (index.php) ကို သေချာပြန်ဆောက်မယ်
cat <<EOF > /var/www/html/index.php
<?php
include "config.php";
if (isset(\$_POST['user'])) {
    if (\$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
        echo "<h1 style='color:green; text-align:center;'>Welcome Admin! Login အောင်မြင်ပါတယ်။</h1>";
    } else {
        echo "<h1 style='color:red; text-align:center;'>Username သို့မဟုတ် Password မှားနေပါတယ်။</h1>";
        echo "<div style='text-align:center;'><a href='index.php'>နောက်သို့ ပြန်သွားရန်</a></div>";
    }
} else {
?>
<div style="text-align:center; margin-top:50px; font-family: sans-serif;">
    <form method="POST">
        <h2>VPN Admin Login</h2>
        Username: <input type="text" name="user" required><br><br>
        Password: <input type="password" name="pass" required><br><br>
        <button type="submit">Login</button>
    </form>
</div>
<?php } ?>
EOF

# ၆။ Apache ကို ပြန်ပွင့်ခိုင်းမယ်
service apache2 restart

echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "User: $adm_user"
echo "Pass: $adm_pass"
echo "Admin Web Panel: http://$MYIP"
echo "------------------------------------------"
