#!/usr/bin/env bash

# Setup script environment
set -o errexit  #Exit immediately if a pipeline returns a non-zero status
set -o errtrace #Trap ERR from shell functions, command substitutions, and commands from subshell
set -o nounset  #Treat unset variables as an error
set -o pipefail #Pipe will exit with last non-zero status if applicable
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR
trap 'die "Script interrupted."' INT

function error_exit() {
  trap - ERR
  local DEFAULT='Unknown failure occured.'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[ERROR:LXC] \e[93m$EXIT@$LINE"
  msg "$FLAG $REASON"
  exit $EXIT
}
function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

# Prepare container OS
msg "Setting up container OS..."
sed -i "/$LANG/ s/\(^# \)//" /etc/locale.gen
locale-gen >/dev/null
apt-get -y purge openssh-{client,server} >/dev/null
apt-get autoremove >/dev/null

# Update container OS
msg "Updating container OS..."
apt-get update >/dev/null
apt-get -qqy upgrade &>/dev/null

# deconz step 1
msg "Deconz step1..."
apt-get -qqy install \
    curl \
    kmod \
    libcap2-bin \
    libqt5core5a \
    libqt5gui5 \
    libqt5network5 \
    libqt5serialport5 \
    libqt5sql5 \
    libqt5websockets5 \
    libqt5widgets5 \
    lsof \
    sqlite3 \
    tigervnc-standalone-server \
    tigervnc-common \
    wmii \
    xfonts-base \
    xfonts-scalable &>/dev/null

# deconz step 2
msg "Deconz step2..."
apt-get clean  >/dev/null
rm -rf /var/lib/apt/lists/* >/dev/null
apt-get update >/dev/null
apt-get -qqy install binutils 
apt-get clean >/dev/null 
rm -rf /var/lib/apt/lists/* >/dev/null 
strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 >/dev/null

# deconz step 3
msg "Deconz step3..."
FOLDER_TMPDECONZ='/deconz_tmp'
mkdir -p $(dirname $FOLDER_TMPDECONZ)
wget -qL http://deconz.dresden-elektronik.de/ubuntu/stable/deconz-2.10.04-qt5.deb -O /deconz_tmp/deconz.deb
# wget -qL https://github.com/Sthopeless/proxmox_d3c0n5/raw/main/setup.sh

# Customize container
msg "Customizing container..."
rm /etc/motd # Remove message of the day after login
rm /etc/update-motd.d/10-uname # Remove kernel information after login
touch ~/.hushlogin # Remove 'Last login: ' and mail notification after login
GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
mkdir -p $(dirname $GETTY_OVERRIDE)
cat << EOF > $GETTY_OVERRIDE
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload
systemctl restart $(basename $(dirname $GETTY_OVERRIDE) | sed 's/\.d//')

# Cleanup container
msg "Cleanup..."
rm -rf /setup.sh /var/{cache,log}/* /var/lib/apt/lists/*
