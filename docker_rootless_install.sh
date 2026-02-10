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

kernel_lt_5_11() {
    local kv
    kv=$(uname -r | cut -d- -f1)

    local major minor
    major=${kv%%.*}
    minor=${kv#*.}
    minor=${minor%%.*}

    if [ "$major" -lt 5 ]; then
        return 0
    elif [ "$major" -eq 5 ] && [ "$minor" -lt 11 ]; then
        return 0
    else
        return 1
    fi
}

echo -e "\e[31;1m[*] Add Docker's official GPG key\e[0m"
apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo -e "\e[31;1m[*] Add the repository to Apt sources and update\e[0m"
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update

echo -e "\e[31;1m[*] Install the Docker packages\e[0m"
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin uidmap fuse-overlayfs fuse3

echo -e "\e[31;1m[*] Disable system-wide Docker daemon\e[0m"
systemctl disable --now docker.service docker.socket
rm /var/run/docker.sock

echo -e "\e[31;1m[*] Run rootless setuptool\e[0m"
run_as_user dockerd-rootless-setuptool.sh install

if kernel_lt_5_11; then
    echo -e "\e[31;1m[*] Kernel < 5.11 detected — using fuse-overlayfs for rootless Docker\e[0m"
    run_as_user mkdir -p "/home/$NORMAL_USER/.config/docker"
    run_as_user cat > "/home/$NORMAL_USER/.config/docker/daemon.json" <<'EOF'
{
  "storage-driver": "fuse-overlayfs"
}
EOF
else
    echo -e "\e[32;1m[*] Kernel >= 5.11 detected — using native overlayfs\e[0m"
fi

echo -e "\e[31;1m[*] Restart Docker\e[0m"
run_as_user systemctl --user restart docker