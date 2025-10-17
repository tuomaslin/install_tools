#!/bin/bash

run_as_user() {
    local cmd="$@"
    local _UID=$(getent passwd $NORMAL_USER | cut -d: -f3)
    local XDG_RUNTIME_DIR="/run/user/$_UID"
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_UID/bus XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR su --whitelist-environment=DBUS_SESSION_BUS_ADDRESS,XDG_RUNTIME_DIR - $NORMAL_USER -c "cd $(pwd) && $cmd"
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

echo -e "\e[31;1m[*] Get docker install file\e[0m"
run_as_user curl -fsSL https://get.docker.com -o get-docker.sh

echo -e "\e[31;1m[*] Run the install file\e[0m"
sh ./get-docker.sh

echo -e "\e[31;1m[*] Install uidmap\e[0m"
apt install -y uidmap

echo -e "\e[31;1m[*] Run rootless setuptool\e[0m"
run_as_user dockerd-rootless-setuptool.sh install

echo -e "\e[31;1m[*] Clean files\e[0m"
run_as_user rm get-docker.sh
