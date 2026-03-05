#!/bin/bash

# ၁။ လိုအပ်တာတွေ အရင်သွင်းမယ်
apt update -y
apt install apache2 php libapache2-mod-php wget -y

# ၂။ IP Address ကို ရှာမယ်
MYIP=$(wget -qO- ipv4.icanhazip.com)

# ၃။ User နဲ့ Pass ကို တစ်ဆင့်ချင်း မေးမယ်
echo "--- VPN Panel Admin Setup ---"
echo -n "Admin Username ပေးပါ: "
read adm_user
echo -n "Admin Password ပေးပါ: "
read adm_pass

# ၄။ Admin အချက်အလက် သိမ်းမယ်
echo "<?php \$admin_user='$adm_user'; \$admin_pass='$adm_pass'; ?>" > /var/www/html/config.php

# ၅။ Login Page (index.php) ကို တစ်ခါတည်း ဆောက်မယ်
cat <<EOF > /var/www/html/index.php
<?php
include "config.php";
if (isset(\$_POST['user'])) {
    if (\$_POST['user'] == \$admin_user && \$_POST['pass'] == \$admin_pass) {
        echo "<h1 style='color:green; text-align:center;'>Welcome Admin! Login အောင်မြင်ပါတယ်။</h1>";
        echo "<p style='text-align:center;'>ဒါက ညီလေးရဲ့ ကိုယ်ပိုင် VPN Panel အခြေခံ မျက်နှာပြင်ပါဗျ။</p>";
    } else {
        echo "<h1 style='color:red; text-align:center;'>User သို့မဟုတ် Password မှားနေပါတယ်။</h1>";
    }
}
?>
<div style="text-align:center; margin-top:50px;">
    <form method="POST">
        <h2>VPN Admin Login</h2>
        Username: <input type="text" name="user" required><br><br>
        Password: <input type="password" name="pass" required><br><br>
        <button type="submit">Login</button>
    </form>
</div>
EOF

# ၆။ Apache ကို ပြန်ပွင့်ခိုင်းမယ်
service apache2 restart

echo "------------------------------------------"
echo "အောင်မြင်စွာ တည်ဆောက်ပြီးပါပြီ!"
echo "Admin Web Panel Link: http://$MYIP"
echo "------------------------------------------"
