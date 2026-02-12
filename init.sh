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
    echo -e "\e[31;1mThis tool needs to be run as root!\e[0m" 1>&2
    exit 1
fi

echo -e "\e[31;1m[*] Update\e[0m"
apt -y update

echo -e "\e[31;1m[*] Install tools:\e[0m"
cat tools.txt | xargs apt -y install

echo -e "\e[31;1m[*] Download Jython\e[0m"
run_as_user wget https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.3/jython-standalone-2.7.3.jar -O "/home/$NORMAL_USER/Downloads/jython-standalone-2.7.3.jar"

echo -e "\e[31;1m[*] Download Seclists\e[0m"
run_as_user git clone --depth 1 https://github.com/danielmiessler/SecLists.git "/home/$NORMAL_USER/seclists"

echo -e "\e[31;1m[*] Download BChecks\e[0m"
run_as_user git clone https://github.com/PortSwigger/BChecks.git "/home/$NORMAL_USER/bchecks"

echo -e "\e[31;1m[*] Modifying .nanorc\e[0m"
run_as_user cp "$PWD/.nanorc" "/home/$NORMAL_USER/.nanorc"

echo -e "\e[31;1m[*] Modifying .bashrc\e[0m"
run_as_user cat << 'EOF' >> "/home/$NORMAL_USER/.bashrc"
alias grep='grep --color=always'

export FZF_CTRL_T_OPTS="
  --preview 'batcat -n --theme \"Monokai Extended\" --color=always {}'
  --height 100%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

export FZF_COMPLETION_TRIGGER='~~'

export FZF_COMPLETION_OPTS='--border --info=inline --preview="cat {}"'

export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'

export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'

source "/usr/share/doc/fzf/examples/key-bindings.bash"
EOF

echo -e "\e[31;1m[*] Disable hot corners\e[0m"
run_as_user gsettings set org.gnome.desktop.interface enable-hot-corners false

echo -e "\e[31;1m[*] Show battery percentage\e[0m"
run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true

echo -e "\e[31;1m[*] Set clock to 24h format and enable seconds\e[0m"
run_as_user gsettings set org.gnome.desktop.interface clock-format "24h"
run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds true

echo -e "\e[31;1m[*] Edit color scheme\e[0m"
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
run_as_user gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

echo -e "\e[31;1m[*] Changing DIR colors\e[0m"
run_as_user cp "$PWD/.dircolors" "/home/$NORMAL_USER/.dircolors"

echo -e "\e[31;1m[*] Modifying .tmux.conf\e[0m"
run_as_user cp "$PWD/.tmux.conf" "/home/$NORMAL_USER/.tmux.conf"

echo -e "\e[31;1m[*] Modifying micro configs\e[0m"
run_as_user cp -r "$PWD/micro" "/home/$NORMAL_USER/.config/"

echo -e "\e[31;1m[*] Set git information:\e[0m"
read -p "Give git username: " git_username
read -p "Give git email: " git_email

run_as_user git config --global user.name "$git_username"
run_as_user git config --global user.email "$git_email"
