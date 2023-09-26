#!/bin/bash

run_as_user() {
    local cmd="$@"
    local _UID=$(getent passwd $NORMAL_USER | cut -d: -f3)
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_UID/bus su --whitelist-environment=DBUS_SESSION_BUS_ADDRESS - $NORMAL_USER -c "cd $(pwd) && $cmd"
}

if [ "$1" ]; then
    NORMAL_USER="$1"
else
    NORMAL_USER="thomal"
fi

if [ "$UID" != "0" ]; then
    echo "This tool needs to be run as root!" 1>&2
    exit 1
fi

apt -y update

echo "[*] Install tools:"
apt -y install nmap wget git sqlmap gobuster ffuf rsync python3-pip gimp jq binwalk \
openvpn python3-requests tree steghide exiftool foremost

echo "[*] Sublime installation"
echo "[*] Add GPG key:"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

echo "[*] Add repository:"
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

echo "[*] Update"
apt-get update

echo "[*] Install sublime"
apt-get install sublime-text

echo "[*] Modifying .bashrc"
run_as_user tee -a /home/$NORMAL_USER/.bashrc <<EOF

alias grep="grep --color=auto"
EOF

echo "[*] Modifying .nanorc"
run_as_user tee -a /home/$NORMAL_USER/.nanorc <<EOF
include /usr/share/nano/*.nanorc

set tabsize 4
set tabstospaces
set constantshow
set softwrap

bind ^' comment main
EOF

echo "[*] Set git information:"
read -p "Give git username: " git_username
read -p "Give git email: " git_email

run_as_user git config --global user.name $git_username
run_as_user git config --global user.email $git_email
