#!/bin/bash

run_as_user() {
    local cmd="$@"
    local _UID=$(getent passwd $NORMAL_USER | cut -d: -f3)
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_UID/bus su --whitelist-environment=DBUS_SESSION_BUS_ADDRESS - $NORMAL_USER -c "cd $(pwd) && $cmd"
}

if [ "$1" ]; then
    NORMAL_USER="$1"
else
    NORMAL_USER="user"
fi

if [ "$UID" != "0" ]; then
    echo "This tool needs to be run as root!" 1>&2
    exit 1
fi

apt -y update

echo -e "\e[31;1m[*] Install tools:\e[0m"
apt -y install nmap wget git sqlmap gobuster ffuf rsync python3-pip gimp jq binwalk \
openvpn python3-requests tree steghide exiftool foremost

echo -e "\e[31;1m[*] Sublime installation\e[0m"
echo -e "\e[31;1m[*] Add GPG key:\e[0m"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

echo -e "\e[31;1m[*] Add repository:\e[0m"
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

echo -e "\e[31;1m[*] Update\e[0m"
apt-get update

echo -e "\e[31;1m[*] Install sublime\e[0m"
apt-get install sublime-text

echo -e "\e[31;1m[*] Modifying .bashrc\e[0m"
run_as_user tee -a "/home/$NORMAL_USER/.bashrc" <<EOF
alias grep="grep --color=auto"
EOF

echo -e "\e[31;1m[*] Edit color scheme\e[0m"
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"

echo -e "\e[31;1m[*] Changing DIR colors\e[0m"
run_as_user tee -a "/home/$NORMAL_USER/.dircolors" <<EOF
DIR 01;94
EOF

echo -e "\e[31;1m[*] Modifying .nanorc\e[0m"
run_as_user tee -a "/home/$NORMAL_USER/.nanorc" <<EOF
include /usr/share/nano/*.nanorc

set tabsize 4
set tabstospaces
set constantshow
set softwrap
set autoindent
set zap
set positionlog
set afterends
set breaklonglines
set fill 139

bind ^G comment main
EOF

echo -e "\e[31;1m[*] Modifying .tmux.conf\e[0m"
run_as_user tee -a "/home/$NORMAL_USER/.tmux.conf" <<EOF

set -g base-index 1
setw -g pane-base-index 1

setw -g automatic-rename on
set -g renumber-windows on
set -g set-titles on
EOF

echo -e "\e[31;1m[*] Set git information:\e[0m"
read -p "Give git username: " git_username
read -p "Give git email: " git_email

run_as_user git config --global user.name "$git_username"
run_as_user git config --global user.email "$git_email"
